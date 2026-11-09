# Phase 9 — Email verification delivery (client issues 4 and 5)

**Issue 4:** verification emails take too long to arrive.
**Issue 5:** verification emails land in Spam.

**This phase changes no application code.** Everything below is done in the
Firebase Console and at your domain registrar. The app already sends the
verification email correctly — the problem is *who it appears to come from*.

> **You do not need to be an email administrator to do this.** Each step says
> exactly where to click, what to copy, and how to check it worked. Where a
> value must come from Firebase or your registrar, it is marked
> **⟨COPY FROM …⟩**. Nothing in this document invents a DNS value for you.

---

## 0. Why this is happening

`FirebaseAuthRepository.sendEmailVerification()` calls Firebase's
`sendEmailVerification()` with no custom configuration, so Firebase sends the
mail itself, from its default address:

```
noreply@careerbridge-97-f58c9.firebaseapp.com
```

That domain is **Google's, not yours**. Three consequences:

| | |
|---|---|
| **Nothing authenticates the mail as yours** | There is no SPF, DKIM or DMARC record under a Wazifly-owned domain saying this mail is legitimate. |
| **The sender looks unrelated to the product** | A recipient sees `careerbridge-97-f58c9.firebaseapp.com` from an app called Wazifly. Spam filters weigh that mismatch, and so do people. |
| **The domain has no sending reputation** | It is shared Firebase infrastructure. You neither own nor can improve its standing. |

This is normal for a default Firebase project and it is exactly what Phase 9
fixes. **It is a configuration gap, not a defect in the app.**

---

## 1. Choose your route first

There are two ways to fix this. Pick one before touching anything — they need
different things from you.

### Route A — Firebase custom domain *(recommended; start here)*

Firebase keeps sending the mail, but from **your** domain
(e.g. `noreply@wazifly.com`). You add DNS records that Firebase gives you.

* **You need:** a domain you control and access to its DNS settings.
* **Effort:** about 30 minutes, plus up to 24 hours of waiting for DNS.
* **Cost:** none.
* **Fixes:** the sender mismatch and the authentication gap — the two causes of
  Spam placement. Usually improves speed as a side effect.

### Route B — Custom SMTP through an email provider

Firebase hands the mail to a provider you own an account with (SendGrid,
Mailgun, Amazon SES, Postmark…), which then delivers it.

* **You need:** a domain *and* an account with an email provider.
* **Effort:** Route A's work, plus provider setup.
* **Cost:** usually a paid plan above a small free tier.
* **Adds over Route A:** delivery logs, bounce and open tracking, and a
  reputation you can manage. **Deliverability becomes the provider's job, not
  Firebase's** — which also makes diagnosis much easier (see §6).

> **Recommendation: do Route A now.** It addresses both reported issues and is
> free. Move to Route B later only if mail still lands in Spam after Route A has
> been verified and given a few days, or if you want delivery logs.
>
> The rest of this runbook is Route A. §7 covers moving to Route B.

---

## 2. Before you start — gather these

| What | Where it comes from | Example shape |
|---|---|---|
| The domain you will send from | You own it | `wazifly.com` |
| DNS access for that domain | Your registrar (GoDaddy, Namecheap, Cloudflare, Google Domains…) | A "DNS" or "DNS records" screen |
| Firebase Console access | An account with **Owner** or **Editor** on `careerbridge-97-f58c9` | — |
| Three test mailboxes | Gmail, Outlook/Hotmail, and one other (Yahoo or a work address) | — |
| Your existing SPF record, if any | See §4, step 1 | `v=spf1 include:... ~all` |

> ⚠️ **Check for an existing SPF record before you begin** (§4 step 1). A domain
> may have **only one** `v=spf1` record. If one already exists — because you use
> Google Workspace, Microsoft 365, or any mail service on this domain — you must
> **merge** Firebase's value into it, not add a second record. Two SPF records
> break email authentication for *all* mail from that domain, including mail you
> send by hand. This is the single most damaging mistake available here.

---

## 3. Firebase email template settings

**Console path: Firebase Console → your project → Build → Authentication →
Templates tab.** (Some Console versions show this under **Security →
Authentication → Templates**.)

1. Open <https://console.firebase.google.com/> and select
   **careerbridge-97-f58c9**.
2. Go to **Authentication**, then the **Templates** tab.
3. Select **Email address verification** from the list.
4. Click the **pencil / edit** icon.
5. Set these fields:

   | Field | What to put | Why |
   |---|---|---|
   | **Sender name** | `Wazifly` | Recipients see a product they recognise, not a project id. |
   | **From** | Leave for now — §4 changes it | Changing the domain is the real fix. |
   | **Reply-to** | A mailbox you actually read | Replies to `noreply@` vanish; a real reply-to improves trust signals. |
   | **Subject** | `Verify your email for Wazifly` | Plain and specific. Avoid "ACTION REQUIRED", "!!!", or all-caps — these are classic spam triggers. |
   | **Message** | Keep Firebase's default wording, change the product name to **Wazifly** | The default is short and link-light, which is good. Do not add images, tracking pixels, or extra links. |

6. **Do not remove the `%LINK%` placeholder.** It is the verification link. If
   it is missing, the email is useless.
7. Click **Save**.
8. Repeat steps 3–7 for **Password reset**. The app uses it
   (`sendPasswordResetEmail`), and it has the same deliverability problem.

**Checkpoint:** register a throwaway account in the app and confirm the email
now shows the sender name "Wazifly" and your new subject. It will still come
from `…firebaseapp.com` — §4 fixes that.

---

## 4. Custom sender domain

### Step 1 — Find out whether you already have an SPF record *(do this first)*

On Windows, open **PowerShell** and run — replacing `wazifly.com` with your
domain:

```powershell
Resolve-DnsName -Type TXT wazifly.com | Select-Object -ExpandProperty Strings
```

Look for a line starting `v=spf1`.

* **No `v=spf1` line** → you have no SPF record. Good, simplest case.
* **One `v=spf1` line** → **write it down exactly.** You will merge into it.
* **Two or more** → your domain's email authentication is already broken. Fix
  that first: merge them into one record before continuing.

### Step 2 — Tell Firebase your domain

1. In **Authentication → Templates → Email address verification**, click the
   **pencil / edit** icon.
2. Click **customize domain**.
3. Enter your domain (e.g. `wazifly.com`) and continue.
4. Firebase now shows **a table of DNS records**. This table is the source of
   truth for everything in §5.

   **⟨COPY FROM FIREBASE⟩** — leave this browser tab open. Copy each row
   exactly: record **type**, **host/name**, and **value**. Do not retype them
   from memory and do not change capitalisation or trailing dots.

   Expect roughly:
   * one or more **TXT** records (domain ownership, and the SPF value), and
   * two **CNAME** records (these are your DKIM keys — their hosts typically
     start with something like `firebase1._domainkey` and `firebase2._domainkey`,
     but **use whatever Firebase shows you**).

### Step 3 — Add the records at your registrar

1. Sign in to your domain registrar and open the **DNS records** screen.
2. For each row in the Firebase table, add a record with exactly that type,
   host and value.

**Three traps that account for most failures:**

* **The host field.** If Firebase shows `wazifly.com` and your registrar expects
  a *subdomain part only*, enter `@`. If Firebase shows
  `firebase1._domainkey.wazifly.com`, enter `firebase1._domainkey`.
  *(Firebase's own documentation notes that GoDaddy specifically requires `@`
  for the apex domain.)* Many registrars append your domain automatically —
  entering the full domain then produces `wazifly.com.wazifly.com`, which is the
  most common cause of "verification never completes".
* **SPF merging.** If step 1 found an existing `v=spf1` record, **edit it**;
  do not add a second. Insert Firebase's `include:` term from the Console table
  before the final `~all` or `-all`. Example of the *shape* — your actual
  include value is **⟨COPY FROM FIREBASE⟩**:

  ```
  Before:  v=spf1 include:_spf.google.com ~all
  After:   v=spf1 include:_spf.google.com include:⟨FIREBASE VALUE⟩ ~all
  ```

  Keep `~all` / `-all` **last**. Anything after it is ignored.
* **CNAME values keep their trailing dot** if the Console shows one.

### Step 4 — Wait, then apply

DNS changes take time — Firebase allows **up to 24 hours**, though it is often
much faster.

1. Return to **Authentication → Templates** periodically.
2. When you see a green **"Verification complete"** message, click
   **Apply Custom Domain**.
3. **This last click is required.** Verified-but-not-applied is a state people
   get stuck in: DNS is correct, yet mail still comes from `…firebaseapp.com`.

**Checkpoint:** register another throwaway account. The email should now come
from your domain.

---

## 5. SPF, DKIM and DMARC — what they are and where each value comes from

In plain terms, these are three DNS records that vouch for your mail. Without
them a receiving server has no reason to believe mail claiming to be from your
domain actually is — so it goes to Spam. **This is the direct cause of issue 5.**

| Record | What it says | Where the value comes from |
|---|---|---|
| **SPF** | "These servers are allowed to send mail for my domain." | **⟨COPY FROM FIREBASE⟩** — the Console table (§4 step 2), merged into any existing record. |
| **DKIM** | "This message carries a signature only my domain could produce." | **⟨COPY FROM FIREBASE⟩** — the two CNAME records in the Console table. You never create these yourself. |
| **DMARC** | "If SPF and DKIM fail, here is what to do, and tell me about it." | **You author this one.** It is a standard record, not a Firebase value — see below. |

### The DMARC record

Firebase does not provide this. Add it yourself **after** §4 is verified and
applied, and after §6 shows SPF and DKIM passing.

| Field | Value |
|---|---|
| Type | `TXT` |
| Host / Name | `_dmarc` (your registrar will make this `_dmarc.wazifly.com`) |
| Value | `v=DMARC1; p=none; rua=mailto:⟨YOUR MAILBOX⟩; fo=1` |

**⟨YOUR MAILBOX⟩** is a real address you read, e.g. `dmarc@wazifly.com`.

* **Start with `p=none`.** It means "monitor, change nothing". It is safe and
  reversible.
* Do **not** start at `p=quarantine` or `p=reject` — if anything is
  misconfigured, those actively send your mail to Spam or have it rejected
  outright, which is worse than the problem you are fixing.
* After two to four weeks of clean reports, you may tighten to
  `p=quarantine`. That is optional and not required to fix issues 4 and 5.

---

## 6. Verify the DNS records and email authentication

### 6a. Check the records exist (PowerShell, on Windows)

Replace `wazifly.com` with your domain. Run each and compare against the
Firebase table.

```powershell
Resolve-DnsName -Type TXT wazifly.com | Select-Object -ExpandProperty Strings
```

```powershell
Resolve-DnsName -Type CNAME firebase1._domainkey.wazifly.com
```

```powershell
Resolve-DnsName -Type TXT _dmarc.wazifly.com | Select-Object -ExpandProperty Strings
```

*(Use whatever DKIM host names Firebase actually gave you in the second
command.)*

**Reading the results:**

| What you see | What it means |
|---|---|
| The exact value from the Firebase table | Correct. |
| `DNS name does not exist` | Not added, not saved, or not propagated yet. Wait, then re-check. |
| A value containing your domain twice (`wazifly.com.wazifly.com`) | The host-field trap from §4 step 3. Fix the host. |
| Two separate `v=spf1` lines | **Fix immediately** — merge into one. |

If you prefer not to use a terminal, <https://mxtoolbox.com/SuperTool.aspx>
checks the same things: enter `spf:wazifly.com`, `dmarc:wazifly.com`, or
`cname:firebase1._domainkey.wazifly.com`.

### 6b. Check that a real email passes authentication

This is the definitive test — DNS records existing is not the same as mail
passing.

1. Register a throwaway account in the app using a **Gmail** address.
2. Open the verification email in Gmail on the **web**.
3. Click the **⋮** menu (top right of the message) → **Show original**.
4. At the top you will see:

   ```
   SPF:    PASS
   DKIM:   PASS
   DMARC:  PASS
   ```

**All three must say PASS.** If any says `FAIL`, `SOFTFAIL` or `NEUTRAL`, go
back to §4 — the records are wrong, not yet propagated, or **Apply Custom
Domain** was never clicked.

### 6c. Get an independent score

1. Open <https://www.mail-tester.com/> and copy the address it shows.
2. Trigger a verification email to that address — register a throwaway account
   in the app using it.
3. Return to mail-tester and click **Then check your score**.

Aim for **8/10 or better**. It will name anything still missing. Treat a score
below 7 as "not finished".

---

## 7. Testing delivery time and spam placement

Do this **before** the change (so you have a baseline) and **again after**.

### The test

For each of your three mailboxes — Gmail, Outlook/Hotmail, and one other:

1. Note the exact time.
2. Register a throwaway account in the app with that address.
3. Watch the mailbox. Record **when it arrives** and **where it lands**.
4. **Check the Spam/Junk folder** before deciding it has not arrived.
5. Repeat **three times per mailbox** on different occasions — once is not a
   measurement.

### Record it

| Mailbox | Sent at | Arrived at | Elapsed | Inbox or Spam |
|---|---|---|---|---|
| Gmail | | | | |
| Outlook | | | | |
| Other | | | | |

### How to read the results

| Elapsed | Verdict |
|---|---|
| Under 30 seconds | Normal and healthy. |
| 30 s – 2 minutes | Acceptable. Common on a first send to a new recipient. |
| 2 – 10 minutes | Usually **greylisting**: the receiver deliberately defers mail from an unfamiliar sender and accepts the retry. Improves on its own as reputation builds. |
| Over 10 minutes, consistently, everywhere | Not normal. See §8. |

> **Important for judging issue 4.** Mail that lands in **Spam** is often
> assumed to be "slow", because nobody sees it until they go looking. Fix the
> Spam placement first and re-measure — in most cases the reported delay largely
> disappears with it.

> **One caveat on your own testing:** repeatedly registering throwaway accounts
> against the same mailbox can itself trigger rate limiting and look like a
> delay. Space tests out, and use a different address each time where you can.

---

## 8. Telling a Firebase problem from an email provider problem

Work down this list in order and stop at the first match.

### Does the email arrive *at all*, in any mailbox (including Spam)?

**No, nowhere.**
→ **Firebase side.** Check, in order:
1. **Authentication → Templates** — does it say the custom domain is *applied*,
   not merely verified?
2. Is the account actually being created? If sign-up itself is failing, no email
   is ever requested. Check **Authentication → Users** for the address.
3. Firebase enforces its own send quotas on the default sender. Many rapid test
   registrations can trip them. Wait an hour and retry.

**No, but only for one provider** (e.g. arrives at Gmail, never at Outlook).
→ **That provider is blocking you**, not Firebase. Complete §4 and §5 — Outlook
in particular is strict about unauthenticated mail. Re-test after DMARC has been
in place for a few days.

**Yes, but in Spam.**
→ Go to §6b and read the authentication results.

### What do the headers say? (§6b)

| Result | Where the problem is | What to do |
|---|---|---|
| `DKIM: FAIL` or no DKIM | **Firebase/DNS side** | The two CNAME records are missing, wrong, or **Apply Custom Domain** was not clicked. Re-check §4. |
| `SPF: FAIL` / `SOFTFAIL` | **DNS side** | SPF record missing, has two `v=spf1` lines, or lacks Firebase's `include:`. Re-check §4 step 3. |
| `DMARC: FAIL` but SPF and DKIM pass | **DNS side** | Usually an *alignment* problem: the visible From domain differs from the authenticated one. Confirm the From address really is your domain, not `…firebaseapp.com`. |
| **All three PASS, still in Spam** | **Reputation or content** — no longer a configuration problem | Your domain is new and has no sending history. Simplify the subject and body (§3), and give it days, not hours. If it persists after a week, that is the signal to move to **Route B** (§1) for a provider with an established sending reputation and real logs. |

### Quick rule of thumb

| Symptom | Almost always |
|---|---|
| Nothing arrives anywhere | Firebase configuration |
| Headers show FAIL | DNS records |
| Headers all PASS but Spam | Reputation / content — a provider question |
| Slow at one provider only | That provider greylisting — usually self-resolving |
| Slow everywhere and getting worse | Firebase send quota or an unapplied custom domain |

---

## 9. Optional code follow-ups — **not done, and not required**

Listed for completeness. None of these are needed to fix issues 4 or 5, and
**no code was changed in this phase.**

* **`ActionCodeSettings`** — `sendEmailVerification()` is currently called with
  no arguments, so the verification link lands on Firebase's default handler.
  Passing `ActionCodeSettings` would let the link return to
  `wazifly.replit.app` directly. A usability improvement, not a deliverability
  one. Requires adding the domain to **Authentication → Settings → Authorized
  domains**.
* **Spam-folder wording** — `verifyEmailNotYet` already says "Check your inbox
  (and spam)". `verifyEmailBody` does not. Adding it there is a one-line l10n
  change in EN and AR.
* **Resend cooldown** — already implemented (30 s), which is correct and should
  stay: it is part of why Firebase's quota is not being tripped in normal use.

---

## 10. If something goes wrong

Every change here is reversible.

| To undo | Do this |
|---|---|
| The custom domain | **Authentication → Templates → edit → customize domain** and remove it. Firebase reverts to `noreply@careerbridge-97-f58c9.firebaseapp.com` — exactly today's behaviour. |
| A DNS record | Delete it at the registrar. Allow the same propagation time. |
| DMARC | Delete the `_dmarc` TXT record, or set it back to `p=none`. |

**The one change that can affect mail beyond this app** is editing an existing
SPF record (§4 step 3). Before you edit it, **copy the original value into a
text file.** If anything breaks, paste it back.

---

## Done when

- [ ] Sender name reads **Wazifly**, subject is plain, `%LINK%` intact (§3)
- [ ] Both **Email address verification** and **Password reset** templates updated
- [ ] Custom domain shows **Verification complete** *and* **Apply Custom Domain** has been clicked (§4)
- [ ] Exactly one `v=spf1` record, containing Firebase's include (§6a)
- [ ] Both DKIM CNAMEs resolve (§6a)
- [ ] `_dmarc` TXT present with `p=none` (§5)
- [ ] Gmail **Show original** shows **SPF / DKIM / DMARC all PASS** (§6b)
- [ ] mail-tester score **8/10 or better** (§6c)
- [ ] Three mailboxes × three sends: **Inbox, under 2 minutes** (§7)

---

## Sources

* [Use a custom domain for Authentication emails — Firebase](https://firebase.google.com/docs/auth/email-custom-domain)
* [Identity Platform Config reference (custom SMTP fields)](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v2/Config)
* [Generating email action links — Firebase](https://firebase.google.com/docs/auth/admin/email-action-links)
