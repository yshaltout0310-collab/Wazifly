import 'package:flutter/material.dart';

/// A tiny, dependency-free Markdown renderer for Career Coach replies.
///
/// The coach's model (Gemini) returns lightweight Markdown — `**bold**`,
/// `*italic*`, `` `code` ``, `-`/`*`/`•` bullet lists, `1.` numbered lists and
/// `#` headings. The chat bubble used to print that raw, so users saw literal
/// asterisks and dashes. This widget renders just that subset — nothing more —
/// so we avoid pulling in (and maintaining) a full Markdown dependency for a
/// single screen.
///
/// **Direction:** the block direction follows the *content*, not the app locale
/// — an Arabic reply is laid out RTL (bullets on the right) even in an English
/// UI, and vice versa. Everything else (colour, base text style) is inherited
/// from the caller so the bubble styling is unchanged.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    required this.text,
    required this.style,
    super.key,
  });

  final String text;
  final TextStyle style;

  static final RegExp _arabic = RegExp(r'[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]');
  static final RegExp _bullet = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final RegExp _heading = RegExp(r'^\s*(#{1,6})\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final dir = _arabic.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
    final blocks = _parseBlocks(text);

    return Directionality(
      textDirection: dir,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) SizedBox(height: blocks[i].topGap),
            blocks[i].build(style),
          ],
        ],
      ),
    );
  }

  /// Splits the text into block-level elements. Blank lines become paragraph
  /// gaps; everything else is a heading, list item or paragraph line.
  List<_Block> _parseBlocks(String src) {
    final out = <_Block>[];
    var blankBefore = false;
    for (final raw in src.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        blankBefore = out.isNotEmpty;
        continue;
      }
      final gap = blankBefore ? 8.0 : 3.0;
      blankBefore = false;

      final h = _heading.firstMatch(line);
      if (h != null) {
        out.add(_Block.heading(h.group(2)!.trim(), h.group(1)!.length, gap));
        continue;
      }
      final b = _bullet.firstMatch(line);
      if (b != null) {
        out.add(_Block.bullet(b.group(1)!.trim(), gap));
        continue;
      }
      final n = _numbered.firstMatch(line);
      if (n != null) {
        out.add(_Block.numbered(n.group(1)!, n.group(2)!.trim(), gap));
        continue;
      }
      out.add(_Block.paragraph(line.trimLeft(), gap));
    }
    return out;
  }
}

/// One block-level element (paragraph / heading / list item).
class _Block {
  _Block._(this._kind, this._content, this.topGap, {this.level = 0, this.marker});

  final _BlockKind _kind;
  final String _content;
  final double topGap;
  final int level;
  final String? marker;

  factory _Block.paragraph(String c, double gap) =>
      _Block._(_BlockKind.paragraph, c, gap);
  factory _Block.heading(String c, int level, double gap) =>
      _Block._(_BlockKind.heading, c, gap, level: level);
  factory _Block.bullet(String c, double gap) =>
      _Block._(_BlockKind.listItem, c, gap, marker: '•');
  factory _Block.numbered(String n, String c, double gap) =>
      _Block._(_BlockKind.listItem, c, gap, marker: '$n.');

  Widget build(TextStyle base) {
    switch (_kind) {
      case _BlockKind.heading:
        // h1/h2 a touch larger + bold; deeper headings just bold.
        final bump = level <= 1 ? 3.0 : (level == 2 ? 1.5 : 0.0);
        final hStyle = base.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (base.fontSize ?? 14) + bump,
        );
        return Text.rich(TextSpan(children: _inline(_content, hStyle)));
      case _BlockKind.paragraph:
        return Text.rich(TextSpan(children: _inline(_content, base)));
      case _BlockKind.listItem:
        // Marker + content in a Row so the marker sits on the leading edge
        // (right under RTL, left under LTR — driven by the ambient Directionality).
        return Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$marker ', style: base),
              Expanded(
                child: Text.rich(TextSpan(children: _inline(_content, base))),
              ),
            ],
          ),
        );
    }
  }

  /// Parses inline `**bold**`, `*italic*` and `` `code` `` into spans. Any
  /// unmatched/dangling marker is treated as literal text so streaming (partial)
  /// input never crashes and never hides characters.
  static List<InlineSpan> _inline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    final buf = StringBuffer();

    void flush() {
      if (buf.isNotEmpty) {
        spans.add(TextSpan(text: buf.toString(), style: base));
        buf.clear();
      }
    }

    var i = 0;
    while (i < text.length) {
      // Bold: **...**
      if (text.startsWith('**', i)) {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          flush();
          spans.add(TextSpan(
            text: text.substring(i + 2, end),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ));
          i = end + 2;
          continue;
        }
      }
      // Italic: *...* (single star, not part of **)
      if (text[i] == '*') {
        final end = text.indexOf('*', i + 1);
        if (end != -1 && end != i + 1) {
          flush();
          spans.add(TextSpan(
            text: text.substring(i + 1, end),
            style: base.copyWith(fontStyle: FontStyle.italic),
          ));
          i = end + 1;
          continue;
        }
      }
      // Inline code: `...`
      if (text[i] == '`') {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          flush();
          spans.add(TextSpan(
            text: text.substring(i + 1, end),
            style: base.copyWith(
              fontFamily: 'monospace',
              fontFamilyFallback: const ['monospace'],
            ),
          ));
          i = end + 1;
          continue;
        }
      }
      buf.write(text[i]);
      i++;
    }
    flush();
    return spans;
  }
}

enum _BlockKind { paragraph, heading, listItem }
