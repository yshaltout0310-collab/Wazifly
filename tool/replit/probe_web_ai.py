#!/usr/bin/env python3
"""Read-only browser diagnostics using Chromium's local DevTools endpoint.

Start Chromium with --remote-debugging-port=9222, then run this script.
Only redacted error details and response statuses are printed, never headers,
App Check tokens, API keys, request content, or successful response bodies.
"""

import argparse
import base64
import html.parser
import json
import os
import re
import socket
import struct
import sys
import time
import urllib.parse
import urllib.request


def redact(value):
    text = str(value)
    key = os.environ.get("RECAPTCHA_SITE_KEY", "")
    if key:
        text = text.replace(key, "[site-key-redacted]")
    text = re.sub(r"AIza[0-9A-Za-z_-]{25,}", "[api-key-redacted]", text)
    text = re.sub(
        r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+",
        "[token-redacted]",
        text,
    )
    return text[:4000]


class DevTools:
    def __init__(self, url):
        url = urllib.parse.urlsplit(url)
        self.socket = socket.create_connection((url.hostname, url.port))
        self.socket.settimeout(1)
        self.buffer = b""
        self.sequence = 0
        self.replies = {}
        self.responses = {}
        self.request_methods = {}
        self.pauses = 0
        self.file_chooser = None
        key = base64.b64encode(os.urandom(16)).decode()
        self.socket.sendall(
            (
                f"GET {url.path} HTTP/1.1\r\nHost: {url.netloc}\r\n"
                "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
            ).encode()
        )
        headers = b""
        while b"\r\n\r\n" not in headers:
            headers += self.socket.recv(4096)
        headers, self.buffer = headers.split(b"\r\n\r\n", 1)
        if b" 101 " not in headers.split(b"\r\n", 1)[0]:
            raise RuntimeError("Local DevTools WebSocket handshake failed")

    def send(self, method, params=None):
        self.sequence += 1
        data = json.dumps(
            {"id": self.sequence, "method": method, "params": params or {}}
        ).encode()
        size = len(data)
        if size < 126:
            header = bytes([0x81, 0x80 | size])
        elif size < 65536:
            header = bytes([0x81, 0xFE]) + struct.pack("!H", size)
        else:
            header = bytes([0x81, 0xFF]) + struct.pack("!Q", size)
        mask = os.urandom(4)
        masked = bytes(byte ^ mask[index % 4] for index, byte in enumerate(data))
        self.socket.sendall(header + mask + masked)
        return self.sequence

    def read_bytes(self, size):
        while len(self.buffer) < size:
            part = self.socket.recv(65536)
            if not part:
                raise RuntimeError("DevTools connection closed")
            self.buffer += part
        result, self.buffer = self.buffer[:size], self.buffer[size:]
        return result

    def receive(self):
        first, second = self.read_bytes(2)
        size = second & 127
        if size == 126:
            size = struct.unpack("!H", self.read_bytes(2))[0]
        elif size == 127:
            size = struct.unpack("!Q", self.read_bytes(8))[0]
        mask = self.read_bytes(4) if second & 128 else None
        data = self.read_bytes(size)
        if mask:
            data = bytes(byte ^ mask[index % 4] for index, byte in enumerate(data))
        if first & 15 == 8:
            raise RuntimeError("DevTools connection closed")
        return json.loads(data) if first & 15 == 1 else None

    def handle(self, message):
        if "id" in message:
            self.replies[message["id"]] = message
            return
        method, params = message.get("method"), message.get("params", {})
        if method == "Runtime.consoleAPICalled":
            text = " ".join(
                str(arg.get("value", arg.get("description", "")))
                for arg in params.get("args", [])
            )
            if any(
                marker in text
                for marker in (
                    "[AppCheck]", "[FirebaseAiService]", "[ResumeAnalyzer]", "[FirebaseService]"
                )
            ):
                print("CONSOLE", redact(text), flush=True)
        elif method == "Runtime.exceptionThrown":
            details = params.get("exceptionDetails", {})
            print(
                "JS_EXCEPTION",
                redact(details.get("exception", {}).get("description", details.get("text"))),
                flush=True,
            )
        elif method == "Debugger.paused":
            description = params.get("data", {}).get("description", "")
            if "subtype" in description or self.pauses < 6:
                self.pauses += 1
                print("CAUGHT_EXCEPTION", redact(description), flush=True)
                frames = [
                    {
                        "function": frame["functionName"],
                        "line": frame["location"]["lineNumber"] + 1,
                        "column": frame["location"]["columnNumber"] + 1,
                    }
                    for frame in params.get("callFrames", [])[:10]
                ]
                print("STACK", json.dumps(frames), flush=True)
            self.send("Debugger.resume")
        elif method == "Network.requestWillBeSent":
            self.request_methods[params["requestId"]] = params["request"]["method"]
        elif method == "Network.responseReceived":
            response = params["response"]
            self.responses[params["requestId"]] = response
            url = urllib.parse.urlsplit(response["url"])
            if url.hostname in (
                "firebaseappcheck.googleapis.com",
                "firebasevertexai.googleapis.com",
            ):
                print(
                    "HTTP", self.request_methods.get(params["requestId"], "?"),
                    response["status"], url.hostname + url.path, flush=True
                )
        elif method == "Network.loadingFailed" and params.get("blockedReason"):
            print("NETWORK_BLOCKED", params.get("errorText"), params["blockedReason"])
        elif method == "Page.fileChooserOpened":
            self.file_chooser = params

    def command(self, method, params=None, timeout=25):
        sequence = self.send(method, params)
        until = time.monotonic() + timeout
        while time.monotonic() < until:
            if sequence in self.replies:
                return self.replies.pop(sequence)
            try:
                message = self.receive()
                if message:
                    self.handle(message)
            except socket.timeout:
                pass
        raise TimeoutError(method)

    def pump(self, seconds):
        until = time.monotonic() + seconds
        while time.monotonic() < until:
            try:
                message = self.receive()
                if message:
                    self.handle(message)
            except socket.timeout:
                pass


def evaluate(client, expression, **options):
    result = client.command(
        "Runtime.evaluate",
        {"expression": expression, "returnByValue": True, **options},
    )
    return result.get("result", {}).get("result", {}).get("value")


def upload_resume(client, url, pdf_path):
    """Exercise the real Flutter picker/controller/repository/AI UI flow."""
    for method in ("Network.enable", "Runtime.enable", "Page.enable"):
        client.command(method)
    client.command("Network.setCacheDisabled", {"cacheDisabled": True})
    client.command("Page.setInterceptFileChooserDialog", {"enabled": True})
    client.command("Page.navigate", {"url": url.split("#")[0] + "#/resume-analyzer"})
    client.pump(25)
    evaluate(client, "document.querySelector('flt-semantics-placeholder')?.click()")
    client.pump(3)
    chosen = evaluate(
        client,
        """(() => {
          const button = [...document.querySelectorAll('[role="button"]')].find(
            e => (e.getAttribute('aria-label') || e.textContent).includes('Choose PDF'));
          if (!button) return false;
          button.click();
          return true;
        })()""",
        userGesture=True,
    )
    if not chosen:
        print("UI_UPLOAD", "Choose PDF button not found; no request sent")
        return False
    client.pump(2)
    if not client.file_chooser or not client.file_chooser.get("backendNodeId"):
        print("UI_UPLOAD", "file chooser did not open; no request sent")
        return False
    client.command(
        "DOM.setFileInputFiles",
        {"backendNodeId": client.file_chooser["backendNodeId"], "files": [os.path.abspath(pdf_path)]},
    )
    print("UI_UPLOAD", "synthetic PDF selected through the real file picker", flush=True)
    until = time.monotonic() + 90
    checked = set()
    while time.monotonic() < until:
        client.pump(1)
        for request_id, response in list(client.responses.items()):
            url = urllib.parse.urlsplit(response["url"])
            if (
                request_id not in checked
                and client.request_methods.get(request_id) != "OPTIONS"
                and url.hostname == "firebasevertexai.googleapis.com"
                and ":generateContent" in url.path
            ):
                body = client.command("Network.getResponseBody", {"requestId": request_id})
                if "result" not in body:
                    continue
                checked.add(request_id)
                result = json.loads(body["result"]["body"])
                if response["status"] != 200:
                    error = result.get("error", {})
                    print(
                        "AI_REQUEST_FAILED",
                        redact(json.dumps({
                            "httpStatus": response["status"],
                            **{field: error.get(field) for field in ("code", "status", "message")},
                        })),
                        flush=True,
                    )
                    return False
                parts = result.get("candidates", [{}])[0].get("content", {}).get("parts", [])
                text = "".join(part.get("text", "") for part in parts)
                analysis = json.loads(re.sub(r"^```(?:json)?\s*|\s*```$", "", text.strip()))
                print(
                    "REAL_ANALYSIS",
                    json.dumps({
                        "httpStatus": response["status"],
                        "model": "gemini-2.5-flash",
                        "atsScore": analysis.get("atsScore"),
                        "careerField": analysis.get("careerField"),
                        "strengthsCount": len(analysis.get("strengths", [])),
                        "suggestionsCount": len(analysis.get("improvementSuggestions", [])),
                    }),
                    flush=True,
                )
                client.pump(3)
                visible = evaluate(
                    client,
                    "({atsResultVisible: document.body.innerText.includes('ATS Score'), "
                    "retryVisible: document.body.innerText.includes('Analyze another resume')})",
                )
                print("UI_RESULT", json.dumps(visible), flush=True)
                return bool(analysis.get("summary")) and isinstance(analysis.get("atsScore"), int)
        security_failure = evaluate(
            client,
            "document.body.innerText.includes(\"The app's security verification failed.\")",
        )
        if security_failure:
            protected_post = any(
                urllib.parse.urlsplit(response["url"]).hostname == "firebasevertexai.googleapis.com"
                and client.request_methods.get(request_id) == "POST"
                for request_id, response in client.responses.items()
            )
            print(
                "UI_SECURITY_FAILURE",
                json.dumps({"specificMessageVisible": True, "protectedRequestSent": protected_post}),
                flush=True,
            )
            return False
    print("AI_REQUEST", "no generateContent response observed within 90 seconds")
    return False


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="https://wazifly.replit.app/")
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--resume-pdf", help="Exercise Resume Analyzer UI with a synthetic PDF")
    args = parser.parse_args()
    request = urllib.request.Request(
        f"http://127.0.0.1:{args.port}/json/new?about:blank", method="PUT"
    )
    with urllib.request.urlopen(request) as response:
        target = json.load(response)
    client = DevTools(target["webSocketDebuggerUrl"])
    try:
        if args.resume_pdf:
            return 0 if upload_resume(client, args.url, args.resume_pdf) else 1
        for method in ("Network.enable", "Runtime.enable", "Page.enable", "Debugger.enable"):
            client.command(method)
        client.command(
            "Page.addScriptToEvaluateOnNewDocument",
            {"source": """
              let appCheckNamespace;
              Object.defineProperty(globalThis, 'firebase_app_check', {
                configurable: true,
                get() { return appCheckNamespace; },
                set(value) {
                  appCheckNamespace = {...value};
                  appCheckNamespace.initializeAppCheck = (...args) => {
                    globalThis.__probeAppCheckCalled = true;
                    globalThis.__probeAppCheckProvider = args[1]?.provider;
                    try {
                      const instance = value.initializeAppCheck(...args);
                      globalThis.__probeAppCheck = instance;
                      return instance;
                    } catch (error) {
                      globalThis.__probeAppCheckError = {
                        name: error.name, code: error.code, message: error.message
                      };
                      throw error;
                    }
                  };
                }
              });
            """},
        )
        client.command("Debugger.setPauseOnExceptions", {"state": "all"})
        client.command("Page.navigate", {"url": args.url})
        client.pump(22)
        client.command("Debugger.setPauseOnExceptions", {"state": "none"})
        client.pump(12)
        # Probe the already-initialized JS SDK without returning its token.
        expression = """(async () => {
          const core = globalThis.firebase_core;
          const check = globalThis.firebase_app_check;
          if (!core || !check) return {stage: 'globals', core: !!core, appCheck: !!check};
          if (!globalThis.__probeAppCheck) return {
            stage: 'initialization', called: !!globalThis.__probeAppCheckCalled,
            error: globalThis.__probeAppCheckError, exports: Object.keys(check)
          };
          try {
            const result = await check.getToken(globalThis.__probeAppCheck, true);
            return {stage: 'app-check-token', tokenAvailable: !!result.token};
          } catch (error) {
            return {stage: 'app-check-token', error: {
              name: error.name, code: error.code, message: error.message
            }};
          }
        })()"""
        result = client.command(
            "Runtime.evaluate",
            {
                "expression": expression,
                "awaitPromise": True,
                "returnByValue": True,
                "timeout": 60000,
            },
            timeout=75,
        )
        print("TOKEN_PROBE", redact(json.dumps(result.get("result", result))), flush=True)
        recaptcha_probe = client.command(
            "Runtime.evaluate",
            {
                "expression": """(async () => {
                  const provider = globalThis.__probeAppCheckProvider;
                  const enterprise = globalThis.grecaptcha?.enterprise;
                  if (!provider || !enterprise) return {provider: !!provider, enterprise: !!enterprise};
                  try {
                    const result = await enterprise.execute(provider._siteKey, {action: 'fire_app_check'});
                    return {stage: 'recaptcha-enterprise', tokenAvailable: !!result};
                  } catch (error) {
                    return {stage: 'recaptcha-enterprise', error: {
                      name: error.name, code: error.code, message: error.message
                    }};
                  }
                })()""",
                "awaitPromise": True,
                "returnByValue": True,
                "timeout": 30000,
            },
            timeout=40,
        )
        print("RECAPTCHA_PROBE", redact(json.dumps(recaptcha_probe.get("result", recaptcha_probe))))
        client.pump(3)
        for request_id, response in list(client.responses.items()):
            url = urllib.parse.urlsplit(response["url"])
            if response["status"] >= 400 and url.hostname in (
                "firebaseappcheck.googleapis.com",
                "firebasevertexai.googleapis.com",
            ):
                body = client.command("Network.getResponseBody", {"requestId": request_id})
                if "result" in body:
                    error = json.loads(body["result"]["body"]).get("error", {})
                    fields = {field: error.get(field) for field in ("code", "status", "message")}
                    print("FIREBASE_ERROR", redact(json.dumps(fields)), flush=True)
            elif "/recaptcha/enterprise/anchor" in url.path:
                body = client.command("Network.getResponseBody", {"requestId": request_id})
                if "result" in body:
                    class ErrorText(html.parser.HTMLParser):
                        def handle_data(self, data):
                            if any(marker in data.lower() for marker in (
                                "invalid", "error for site owner", "not allowed", "not authorized"
                            )):
                                print("RECAPTCHA_FRAME", redact(data.strip()), flush=True)
                    ErrorText().feed(body["result"]["body"])
    finally:
        client.socket.close()


if __name__ == "__main__":
    sys.exit(main())
