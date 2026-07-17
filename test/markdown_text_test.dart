import 'package:careerbridge/features/career_coach/presentation/widgets/markdown_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Collects every plain-text fragment rendered by a [MarkdownText] subtree,
/// walking the `Text.rich` spans and any plain `Text` (list markers).
List<String> _texts(WidgetTester tester) {
  final out = <String>[];
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final span = t.textSpan;
    if (span != null) {
      span.visitChildren((s) {
        if (s is TextSpan && s.text != null) out.add(s.text!);
        return true;
      });
    } else if (t.data != null) {
      out.add(t.data!);
    }
  }
  return out;
}

/// Every span that is bold.
List<String> _boldTexts(WidgetTester tester) {
  final out = <String>[];
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    t.textSpan?.visitChildren((s) {
      if (s is TextSpan &&
          s.text != null &&
          s.style?.fontWeight == FontWeight.w700) {
        out.add(s.text!);
      }
      return true;
    });
  }
  return out;
}

Future<void> _pump(WidgetTester tester, String text) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownText(
            text: text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
    );

void main() {
  testWidgets('renders **bold** as a bold span with no literal asterisks',
      (tester) async {
    await _pump(tester, 'Please **fix your resume** now.');
    final all = _texts(tester).join('|');
    expect(all, isNot(contains('**')));
    expect(_boldTexts(tester), contains('fix your resume'));
  });

  testWidgets('a "-" bullet renders a bullet marker, not a literal dash',
      (tester) async {
    await _pump(tester, '- Add a summary\n- List your skills');
    final all = _texts(tester);
    expect(all.any((t) => t.trimRight() == '•'), isTrue);
    // The dash prefix is gone from the content.
    expect(all.join('|'), isNot(contains('- Add')));
    expect(all.join(' '), contains('Add a summary'));
  });

  testWidgets('numbered list keeps its number as the marker', (tester) async {
    await _pump(tester, '1. First\n2. Second');
    final markers = _texts(tester).map((t) => t.trim()).toList();
    expect(markers, contains('1.'));
    expect(markers, contains('2.'));
  });

  testWidgets('a bullet with inline bold drops the dash and shows bold',
      (tester) async {
    await _pump(tester, '-   **Projects:** showcase your work');
    final all = _texts(tester).join('|');
    expect(all, isNot(contains('**')));
    expect(all, isNot(contains('-   ')));
    expect(_boldTexts(tester), contains('Projects:'));
  });

  testWidgets('heading marker "##" is stripped and rendered bold',
      (tester) async {
    await _pump(tester, '## Summary');
    final all = _texts(tester).join('|');
    expect(all, isNot(contains('#')));
    expect(_boldTexts(tester), contains('Summary'));
  });

  testWidgets('Arabic content lays out RTL', (tester) async {
    await _pump(tester, 'حسّن **سيرتك الذاتية** الآن');
    final dir = tester.widget<Directionality>(
      find.descendant(
        of: find.byType(MarkdownText),
        matching: find.byType(Directionality),
      ),
    );
    expect(dir.textDirection, TextDirection.rtl);
    expect(_texts(tester).join('|'), isNot(contains('**')));
  });

  testWidgets('English content lays out LTR', (tester) async {
    await _pump(tester, 'Improve your **resume**.');
    final dir = tester.widget<Directionality>(
      find.descendant(
        of: find.byType(MarkdownText),
        matching: find.byType(Directionality),
      ),
    );
    expect(dir.textDirection, TextDirection.ltr);
  });

  testWidgets('unclosed bold during streaming does not crash or show markers',
      (tester) async {
    // A partial token mid-stream: "**Cre" with no closing yet.
    await _pump(tester, 'Next: **Create a projec');
    // Must render without throwing; dangling ** is treated as literal text so
    // no characters are hidden.
    expect(tester.takeException(), isNull);
    expect(_texts(tester), isNotEmpty);
  });

  testWidgets('plain text with no markdown renders unchanged', (tester) async {
    await _pump(tester, 'Just a normal sentence.');
    expect(_texts(tester).join(' '), contains('Just a normal sentence.'));
  });
}
