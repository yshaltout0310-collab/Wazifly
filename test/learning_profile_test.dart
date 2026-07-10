import 'package:careerbridge/shared/models/learning_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 10);

  LearningInterest make(LearningCategory c, String label, {String? note}) =>
      LearningInterest.create(category: c, label: label, now: now, note: note);

  test('deterministic id de-dupes same (category,label) case-insensitively', () {
    final a = make(LearningCategory.skillsToLearn, 'Machine Learning');
    final b = make(LearningCategory.skillsToLearn, '  machine learning ');
    expect(a.id, b.id);
    final c = make(LearningCategory.technologies, 'Machine Learning');
    expect(a.id, isNot(c.id));
  });

  test('added is idempotent by id (replaces, no duplicate)', () {
    var p = LearningProfile.empty('u1');
    p = p.added(make(LearningCategory.goals, 'Lead a team'), now);
    p = p.added(make(LearningCategory.goals, 'Lead a team', note: 'in 2 yrs'), now);
    expect(p.interests.length, 1);
    expect(p.byCategory(LearningCategory.goals).single.note, 'in 2 yrs');
  });

  test('edited replaces the old id (label change re-keys)', () {
    var p = LearningProfile.empty('u1');
    final orig = make(LearningCategory.technologies, 'Fluter');
    p = p.added(orig, now);
    final fixed = orig.copyWith(label: 'Flutter');
    p = p.edited(orig.id, fixed, now);
    expect(p.interests.length, 1);
    expect(p.byCategory(LearningCategory.technologies).single.label, 'Flutter');
  });

  test('removed drops by id', () {
    var p = LearningProfile.empty('u1');
    final i = make(LearningCategory.industries, 'Fintech');
    p = p.added(i, now);
    p = p.removed(i.id, now);
    expect(p.isEmpty, true);
  });

  test('search matches label + note across categories', () {
    var p = LearningProfile.empty('u1');
    p = p.added(make(LearningCategory.skillsToLearn, 'Rust'), now);
    p = p.added(
        make(LearningCategory.goals, 'Ship an app', note: 'using Rust'), now);
    p = p.added(make(LearningCategory.industries, 'Gaming'), now);
    final hits = p.search('rust');
    expect(hits.length, 2);
    expect(p.search('gaming').single.label, 'Gaming');
    expect(p.search('').length, 3);
  });

  test('byCategory returns newest first', () {
    var p = LearningProfile.empty('u1');
    p = p.added(
        LearningInterest.create(
            category: LearningCategory.careerPaths,
            label: 'Old',
            now: DateTime(2026, 1, 1)),
        now);
    p = p.added(
        LearningInterest.create(
            category: LearningCategory.careerPaths,
            label: 'New',
            now: DateTime(2026, 6, 1)),
        now);
    final list = p.byCategory(LearningCategory.careerPaths);
    expect(list.first.label, 'New');
  });

  test('JSON round-trips', () {
    var p = LearningProfile.empty('u1');
    p = p.added(make(LearningCategory.skillsToLearn, 'Go', note: 'backend'), now);
    p = p.added(make(LearningCategory.goals, 'Mentor others'), now);
    final back = LearningProfile.fromJson(p.toJson());
    expect(back.uid, 'u1');
    expect(back.interests.length, 2);
    expect(back.contains(LearningCategory.skillsToLearn, 'Go'), true);
  });

  test('fromJson drops empty-label entries defensively', () {
    final p = LearningProfile.fromJson(const {
      'uid': 'u1',
      'interests': [
        {'category': 'goals', 'label': ''},
        {'category': 'goals', 'label': 'Valid'},
      ],
    });
    expect(p.interests.length, 1);
  });
}
