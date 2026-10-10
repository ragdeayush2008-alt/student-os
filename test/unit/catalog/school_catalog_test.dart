import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/catalog/school_catalog_data.dart';
import 'package:student_os/data/models/catalog/catalog_node.dart';
import 'package:student_os/data/models/catalog/course_category.dart';

void main() {
  group('School & Senior Secondary Catalog — Phase 2', () {
    late CourseCatalogService catalog;

    setUp(() {
      catalog = CourseCatalogService.instance;
      catalog.loadDefaults();
    });

    // ─── 1. Primary School (Classes 1–5) ───────────────────────────────────

    test('Primary School catalog covers Class 1 to 5 with core foundational subjects', () {
      final cbsePrimary = catalog.getCourseById('cbse_primary');
      expect(cbsePrimary, isNotNull);
      expect(cbsePrimary!.category, CourseCategory.school);

      final curr = cbsePrimary.activeCurriculum!;
      expect(curr.structure.length, 5); // Classes 1-5

      // Class 1
      final class1 = curr.findNodeById('node_cbse_class_1');
      expect(class1, isNotNull);
      expect(class1!.name, 'Class 1');
      expect(class1.subjects.any((s) => s.name == 'English' && s.isCompulsory), isTrue);
      expect(class1.subjects.any((s) => s.name == 'Mathematics' && s.isCompulsory), isTrue);
      expect(class1.subjects.any((s) => s.name.contains('EVS') && s.isCompulsory), isTrue);

      // Class 5
      final class5 = curr.findNodeById('node_cbse_class_5');
      expect(class5, isNotNull);
      expect(class5!.subjects.any((s) => s.name == 'Computer Studies' && s.isOptional), isTrue);
      expect(class5.subjects.any((s) => s.name == 'Art & Craft' && s.isOptional), isTrue);
    });

    // ─── 2. Middle School (Classes 6–8) ────────────────────────────────────

    test('Middle School catalog covers Class 6 to 8 with Science and Social Science', () {
      final cbseMiddle = catalog.getCourseById('cbse_middle');
      expect(cbseMiddle, isNotNull);
      expect(cbseMiddle!.category, CourseCategory.school);

      final curr = cbseMiddle.activeCurriculum!;
      expect(curr.structure.length, 3); // Classes 6-8

      final class8 = curr.findNodeById('node_cbse_class_8');
      expect(class8, isNotNull);

      // Compulsory core
      expect(class8!.subjects.any((s) => s.name == 'English' && s.isCompulsory), isTrue);
      expect(class8.subjects.any((s) => s.name == 'Mathematics' && s.isCompulsory), isTrue);
      expect(class8.subjects.any((s) => s.name == 'Science' && s.isCompulsory), isTrue);
      expect(class8.subjects.any((s) => s.name == 'Social Science' && s.isCompulsory), isTrue);

      // Elective & Optional
      expect(class8.subjects.any((s) => s.name.contains('Third Language') && s.isElective), isTrue);
      expect(class8.subjects.any((s) => s.name.contains('ICT') && s.isOptional), isTrue);
    });

    // ─── 3. Secondary School (Classes 9–10) & Boards ───────────────────────

    test('Secondary School (Class 9-10) supports CBSE, ICSE, and State Board with verified codes', () {
      final schoolCourses = catalog.getCoursesByCategory(CourseCategory.school);
      expect(schoolCourses.any((c) => c.id == 'cbse_class_9'), isTrue);
      expect(schoolCourses.any((c) => c.id == 'cbse_class_10'), isTrue);
      expect(schoolCourses.any((c) => c.id == 'icse_class_10'), isTrue);
      expect(schoolCourses.any((c) => c.id == 'state_board_class_10'), isTrue);

      // CBSE Class 10 verification
      final cbse10 = catalog.getCourseById('cbse_class_10')!;
      final class10Node = cbse10.activeCurriculum!.structure.first;

      final mathStd = class10Node.subjects.firstWhere((s) => s.code == '041');
      expect(mathStd.name, 'Mathematics (Standard)');
      expect(mathStd.isCompulsory, isTrue);

      final mathBasic = class10Node.subjects.firstWhere((s) => s.code == '241');
      expect(mathBasic.name, 'Mathematics (Basic)');
      expect(mathBasic.isElective, isTrue);

      final science = class10Node.subjects.firstWhere((s) => s.code == '086');
      expect(science.name, 'Science');

      final sst = class10Node.subjects.firstWhere((s) => s.code == '087');
      expect(sst.name, 'Social Science');

      // Skill subjects are electives, not compulsory
      final itSkill = class10Node.subjects.firstWhere((s) => s.code == '402');
      expect(itSkill.name, 'Information Technology');
      expect(itSkill.isElective, isTrue);

      final aiSkill = class10Node.subjects.firstWhere((s) => s.code == '417');
      expect(aiSkill.name, 'Artificial Intelligence');
      expect(aiSkill.isElective, isTrue);

      // ICSE Class 10 verification with Group structure
      final icse10 = catalog.getCourseById('icse_class_10')!;
      final icseNode = icse10.activeCurriculum!.structure.first;
      expect(icseNode.children.length, 3); // Group I, Group II, Group III
      expect(icseNode.children.any((g) => g.name.contains('Group I')), isTrue);
    });

    // ─── 4. Senior Secondary (Classes 11–12) & Streams ─────────────────────

    test('Class 11 CBSE supports Science (PCM, PCB, PCMB) streams with exact codes', () {
      final cbse11 = catalog.getCourseById('cbse_class_11');
      expect(cbse11, isNotNull);
      expect(cbse11!.category, CourseCategory.seniorSecondary);

      final class11Node = cbse11.activeCurriculum!.structure.first;

      // PCM Stream
      final pcm = class11Node.findNodeById('cbse_c11_sci_pcm')!;
      expect(pcm.type, CatalogNodeType.stream);
      expect(pcm.subjects.any((s) => s.code == '301' && s.name == 'English Core' && s.isCompulsory), isTrue);
      expect(pcm.subjects.any((s) => s.code == '042' && s.name == 'Physics' && s.isCompulsory), isTrue);
      expect(pcm.subjects.any((s) => s.code == '043' && s.name == 'Chemistry' && s.isCompulsory), isTrue);
      expect(pcm.subjects.any((s) => s.code == '041' && s.name == 'Mathematics' && s.isCompulsory), isTrue);
      expect(pcm.subjects.any((s) => s.code == '083' && s.name == 'Computer Science' && s.isElective), isTrue);
      expect(pcm.subjects.any((s) => s.code == '048' && s.name == 'Physical Education' && s.isElective), isTrue);

      // PCB Stream
      final pcb = class11Node.findNodeById('cbse_c11_sci_pcb')!;
      expect(pcb.subjects.any((s) => s.code == '044' && s.name == 'Biology' && s.isCompulsory), isTrue);
      expect(pcb.subjects.any((s) => s.code == '037' && s.name == 'Psychology' && s.isElective), isTrue);

      // PCMB Stream
      final pcmb = class11Node.findNodeById('cbse_c11_sci_pcmb')!;
      expect(pcmb.subjects.any((s) => s.code == '041' && s.name == 'Mathematics' && s.isCompulsory), isTrue);
      expect(pcmb.subjects.any((s) => s.code == '044' && s.name == 'Biology' && s.isCompulsory), isTrue);
    });

    test('Class 11 & 12 CBSE supports Commerce (Math, Applied Math, Without Math)', () {
      final cbse12 = catalog.getCourseById('cbse_class_12')!;
      final class12Node = cbse12.activeCurriculum!.structure.first;

      // Commerce with Core Math (041)
      final commMath = class12Node.findNodeById('cbse_c12_comm_math')!;
      expect(commMath.subjects.any((s) => s.code == '055' && s.name == 'Accountancy' && s.isCompulsory), isTrue);
      expect(commMath.subjects.any((s) => s.code == '054' && s.name == 'Business Studies' && s.isCompulsory), isTrue);
      expect(commMath.subjects.any((s) => s.code == '030' && s.name == 'Economics' && s.isCompulsory), isTrue);
      expect(commMath.subjects.any((s) => s.code == '041' && s.name == 'Mathematics' && s.isCompulsory), isTrue);

      // Commerce with Applied Math (241)
      final commAppMath = class12Node.findNodeById('cbse_c12_comm_applied_math')!;
      expect(commAppMath.subjects.any((s) => s.code == '241' && s.name == 'Applied Mathematics' && s.isCompulsory), isTrue);

      // Commerce without Math
      final commNoMath = class12Node.findNodeById('cbse_c12_comm_no_math')!;
      expect(commNoMath.subjects.any((s) => s.code == '041'), isFalse);
      expect(commNoMath.subjects.any((s) => s.code == '241'), isFalse);
      expect(commNoMath.subjects.any((s) => s.code == '066' && s.name == 'Entrepreneurship' && s.isElective), isTrue);
    });

    test('Class 11 & 12 CBSE supports Humanities / Arts with major electives', () {
      final cbse11 = catalog.getCourseById('cbse_class_11')!;
      final class11Node = cbse11.activeCurriculum!.structure.first;

      final arts = class11Node.findNodeById('cbse_c11_humanities')!;
      expect(arts.type, CatalogNodeType.stream);
      expect(arts.subjects.any((s) => s.code == '301' && s.name == 'English Core' && s.isCompulsory), isTrue);
      expect(arts.subjects.any((s) => s.code == '027' && s.name == 'History' && s.isElective), isTrue);
      expect(arts.subjects.any((s) => s.code == '028' && s.name == 'Political Science' && s.isElective), isTrue);
      expect(arts.subjects.any((s) => s.code == '029' && s.name == 'Geography' && s.isElective), isTrue);
      expect(arts.subjects.any((s) => s.code == '039' && s.name == 'Sociology' && s.isElective), isTrue);
      expect(arts.subjects.any((s) => s.code == '074' && s.name == 'Legal Studies' && s.isElective), isTrue);
    });

    test('ISC and State Board Class 12 Senior Secondary courses are populated', () {
      final isc12 = catalog.getCourseById('isc_class_12');
      expect(isc12, isNotNull);
      expect(isc12!.category, CourseCategory.seniorSecondary);
      expect(isc12.activeCurriculum!.structure.first.children.length, 3); // Science, Commerce, Humanities

      final state12 = catalog.getCourseById('state_board_class_12');
      expect(state12, isNotNull);
      expect(state12!.category, CourseCategory.seniorSecondary);
      expect(state12.activeCurriculum!.structure.first.children.length, 3);
    });

    test('Catalog course search works across school categories and boards', () {
      final cbseResults = catalog.searchCourses('cbse');
      expect(cbseResults.length, greaterThanOrEqualTo(5));

      final scienceResults = catalog.searchCourses('class 11');
      expect(scienceResults.length, 1);
      expect(scienceResults.first.name, 'Class 11 CBSE');

      final seniorSec = catalog.getCoursesByCategory(CourseCategory.seniorSecondary);
      expect(seniorSec.length, 4); // CBSE 11, CBSE 12, ISC 12, State Board 12
    });

    test('Instantiating StudentSubject from Class 10 CBSE Math preserves code and metadata', () {
      final cbse10 = catalog.getCourseById('cbse_class_10')!;
      final mathSubj = cbse10.activeCurriculum!.findSubjectById('cbse_c10_math_std')!;

      final studentSubject = catalog.createStudentSubject(
        catalogSubject: mathSubj,
        courseId: cbse10.id,
        catalogVersion: cbse10.catalogVersion,
      );

      expect(studentSubject.name, 'Mathematics (Standard)');
      expect(studentSubject.shortName, 'Maths Std');
      expect(studentSubject.code, '041');
      expect(studentSubject.catalogCourseId, 'cbse_class_10');
      expect(studentSubject.catalogSubjectId, 'cbse_c10_math_std');
      expect(studentSubject.catalogVersion, SchoolCatalogData.currentVersion);
      expect(studentSubject.isCatalogLinked, isTrue);
    });
  });
}
