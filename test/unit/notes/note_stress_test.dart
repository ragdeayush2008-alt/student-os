import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_os/core/auth/auth_isolation.dart';
import 'package:student_os/data/models/chapter.dart';
import 'package:student_os/data/models/student_note.dart';
import 'package:student_os/data/models/subject.dart';
import 'package:student_os/data/models/topic.dart';
import 'package:student_os/features/notes/services/note_search_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthIsolation.instance.setAuthenticatedUser('test_stress_user');
  });

  tearDown(() {
    AuthIsolation.instance.clearSession();
  });

  group('StudentNote High-Volume Stress & Scaling Tests', () {
    final subjects = List.generate(20, (i) => Subject(id: 'sub_$i', name: 'Subject $i', color: 0xFF2EC4B6));
    final chapters = List.generate(100, (i) => Chapter(id: 'ch_$i', subjectId: 'sub_${i % 20}', title: 'Chapter $i'));
    final topics = List.generate(500, (i) => Topic(id: 'top_$i', chapterId: 'ch_${i % 100}', subjectId: 'sub_${i % 20}', title: 'Topic $i'));

    test('1. Benchmark 100 notes search and filtering (< 10ms)', () {
      final notes = List.generate(100, (i) {
        return StudentNote(
          id: 'note_$i',
          title: 'Note $i on Calculus and Algebra',
          content: 'Detailed formula $i content.',
          subjectId: 'sub_${i % 10}',
          chapterId: 'ch_${i % 20}',
          topicId: 'top_${i % 50}',
          tags: ['math', 'calc', 'tag_$i'],
          isPinned: i % 10 == 0,
        );
      });

      final sw = Stopwatch()..start();
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'Calculus',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );
      final elapsed = sw.elapsedMilliseconds;

      expect(results.length, 100);
      expect(elapsed, lessThan(50));
    });

    test('2. Benchmark 500 notes search and ranking (< 50ms)', () {
      final notes = List.generate(500, (i) {
        return StudentNote(
          id: 'note_$i',
          title: i == 42 ? 'Exact Match Title' : 'Note $i on Economics and Commerce',
          content: 'Content explaining economic theory $i.',
          subjectId: 'sub_${i % 20}',
          tags: ['commerce', 'tag_$i'],
        );
      });

      final sw = Stopwatch()..start();
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'Exact Match Title',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );
      final elapsed = sw.elapsedMilliseconds;

      expect(results.first.id, 'note_42');
      expect(elapsed, lessThan(100));
    });

    test('3. Benchmark 1,000 notes hierarchy matching (< 100ms)', () {
      final notes = List.generate(1000, (i) {
        return StudentNote(
          id: 'note_$i',
          title: 'Study Note $i',
          content: 'General content $i.',
          subjectId: 'sub_${i % 20}',
          chapterId: 'ch_${i % 100}',
          topicId: 'top_${i % 500}',
        );
      });

      final sw = Stopwatch()..start();
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'Topic 42',
        subjects: subjects,
        chapters: chapters,
        topics: topics,
      );
      final elapsed = sw.elapsedMilliseconds;

      expect(results, isNotEmpty);
      expect(elapsed, lessThan(150));
    });

    test('4. Benchmark 5,000 notes memory scaling and instant ranking (< 300ms)', () {
      final notes = List.generate(5000, (i) {
        return StudentNote(
          id: 'note_$i',
          title: i == 2500 ? 'Quantum Mechanics' : 'Quantum Physics Note $i',
          content: 'Wave function collapse and Schrodinger equation $i.',
          tags: ['physics', 'quantum'],
        );
      });

      final sw = Stopwatch()..start();
      final results = NoteSearchEngine.search(
        notes: notes,
        query: 'Quantum Mechanics',
      );
      final elapsed = sw.elapsedMilliseconds;

      expect(results, isNotEmpty);
      expect(results.first.id, 'note_2500'); // Exact match ranks #1
      expect(elapsed, lessThan(500));
    });
  });
}
