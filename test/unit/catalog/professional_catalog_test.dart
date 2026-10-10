import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/models/catalog/catalog_node.dart';
import 'package:student_os/data/models/catalog/course_category.dart';

void main() {
  group('Professional Courses Catalog — Phase 4', () {
    late CourseCatalogService catalog;

    setUp(() {
      catalog = CourseCatalogService.instance;
      catalog.clearCatalog();
      catalog.loadDefaults();
    });

    test('CA Foundation has representative papers', () {
      final caFound = catalog.getCourseById('ca_foundation');
      expect(caFound, isNotNull);
      expect(caFound!.category, CourseCategory.professional);
      expect(caFound.authority, 'ICAI');

      final curr = caFound.activeCurriculum!;
      final levelNode = curr.structure.first;
      expect(levelNode.type, CatalogNodeType.level);
      expect(levelNode.subjects.length, 4);

      expect(levelNode.subjects.any((s) => s.name.contains('Accounting') && s.isCompulsory), isTrue);
      expect(levelNode.subjects.any((s) => s.name.contains('Business Law')), isTrue);
    });

    test('CA Intermediate has Group I and Group II structure', () {
      final caInt = catalog.getCourseById('ca_intermediate');
      expect(caInt, isNotNull);
      expect(caInt!.category, CourseCategory.professional);
      expect(caInt.authority, 'ICAI');

      final curr = caInt.activeCurriculum!;
      final levelNode = curr.structure.first;
      expect(levelNode.children.length, 2);

      final group1 = levelNode.findNodeById('node_ca_intermediate_group1');
      expect(group1, isNotNull);
      expect(group1!.type, CatalogNodeType.group);
      expect(group1.subjects.length, 4);
      expect(group1.subjects.every((s) => s.type.name == 'groupSpecific'), isTrue);

      final group2 = levelNode.findNodeById('node_ca_intermediate_group2');
      expect(group2, isNotNull);
      expect(group2!.subjects.length, 4);

      expect(
        group1.subjects.any((s) => s.name == 'Accounting & Finance'),
        isTrue,
      );
    });

    test('CA Final has Group I and Group II structure', () {
      final caFinal = catalog.getCourseById('ca_final');
      expect(caFinal, isNotNull);

      final curr = caFinal!.activeCurriculum!;
      final levelNode = curr.structure.first;
      expect(levelNode.children.length, 2);

      final group1 = levelNode.findNodeById('node_ca_final_group1');
      expect(group1, isNotNull);
      expect(group1!.subjects.length, 3);

      final group2 = levelNode.findNodeById('node_ca_final_group2');
      expect(group2, isNotNull);
      expect(group2!.subjects.length, 3);
    });

    test('CS has CSEET, Executive, and Professional levels', () {
      final csCseet = catalog.getCourseById('cs_cseet');
      expect(csCseet, isNotNull);
      expect(csCseet!.authority, 'ICSI');

      final csExec = catalog.getCourseById('cs_executive');
      expect(csExec, isNotNull);
      expect(csExec!.authority, 'ICSI');

      final csProf = catalog.getCourseById('cs_professional');
      expect(csProf, isNotNull);
      expect(csProf!.authority, 'ICSI');

      final execCurr = csExec.activeCurriculum!;
      final execNode = execCurr.structure.first;
      expect(execNode.children.length, 2);
      expect(execNode.children.every((m) => m.type == CatalogNodeType.module), isTrue);
    });

    test('CMA has Foundation, Intermediate, Final with group structure', () {
      final cmaFound = catalog.getCourseById('cma_foundation');
      expect(cmaFound, isNotNull);
      expect(cmaFound!.authority, 'ICMAI');

      final cmaInt = catalog.getCourseById('cma_intermediate');
      expect(cmaInt, isNotNull);

      final cmaFinal = catalog.getCourseById('cma_final');
      expect(cmaFinal, isNotNull);

      final intCurr = cmaInt!.activeCurriculum!;
      final intNode = intCurr.structure.first;
      expect(intNode.children.length, 2);

      final group1 = intNode.findNodeById('node_cma_int_group1');
      expect(group1!.type, CatalogNodeType.group);
      expect(group1.subjects.length, 2);
    });

    test('ACCA has Applied Knowledge, Applied Skills, Strategic Professional', () {
      final accaAk = catalog.getCourseById('acca_applied_knowledge');
      expect(accaAk, isNotNull);
      expect(accaAk!.authority, 'ACCA');

      final accaAs = catalog.getCourseById('acca_applied_skills');
      expect(accaAs, isNotNull);

      final accaSp = catalog.getCourseById('acca_strategic_professional');
      expect(accaSp, isNotNull);
    });

    test('ACCA Strategic Professional has compulsory and optional papers', () {
      final accaSp = catalog.getCourseById('acca_strategic_professional')!;
      final curr = accaSp.activeCurriculum!;
      final levelNodeActual = curr.structure.first;

      final compGroup = levelNodeActual.findNodeById('node_acca_sp_compulsory');
      expect(compGroup, isNotNull);
      expect(compGroup!.subjects.every((s) => s.isCompulsory), isTrue);

      final optGroup = levelNodeActual.findNodeById('node_acca_sp_optional');
      expect(optGroup, isNotNull);
      expect(optGroup!.subjects.every((s) => s.isOptional), isTrue);
    });

    test('CFA has Level I, Level II, Level III', () {
      final cfaL1 = catalog.getCourseById('cfa_level1');
      expect(cfaL1, isNotNull);
      expect(cfaL1!.authority, 'CFA Institute');

      final cfaL2 = catalog.getCourseById('cfa_level2');
      expect(cfaL2, isNotNull);

      final cfaL3 = catalog.getCourseById('cfa_level3');
      expect(cfaL3, isNotNull);

      final l1Curr = cfaL1.activeCurriculum!;
      final l1Node = l1Curr.structure.first;
      expect(l1Node.subjects.length, 10);

      final l3Curr = cfaL3!.activeCurriculum!;
      final l3Node = l3Curr.structure.first;
      expect(l3Node.subjects.length, 6);
    });

    test('FRM has Part I and Part II with paper group structure', () {
      final frmP1 = catalog.getCourseById('frm_part1');
      expect(frmP1, isNotNull);
      expect(frmP1!.authority, 'GARP');

      final frmP2 = catalog.getCourseById('frm_part2');
      expect(frmP2, isNotNull);

      final p1Curr = frmP1.activeCurriculum!;
      final p1Node = p1Curr.structure.first;
      expect(p1Node.type, CatalogNodeType.level);
      expect(p1Node.children.length, 2);

      final p1PaperGroups = p1Node.children.where((c) => c.type == CatalogNodeType.paperGroup);
      expect(p1PaperGroups.length, 2);

      final p2Curr = frmP2!.activeCurriculum!;
      final p2Node = p2Curr.structure.first;
      expect(p2Node.children.length, 3);
    });

    test('Actuarial supports IFoA and SOA providers', () {
      final iamAct = catalog.getCourseById('actuarial_iam');
      expect(iamAct, isNotNull);
      expect(iamAct!.authority, 'Institute & Faculty of Actuaries');

      final soaAct = catalog.getCourseById('actuarial_soa');
      expect(soaAct, isNotNull);
      expect(soaAct!.authority, 'Society of Actuaries');

      final iamCurr = iamAct.activeCurriculum!;
      final iamNode = iamCurr.structure.first;
      expect(iamNode.children.length, 2);

      final coreModule = iamNode.findNodeById('node_iam_core');
      expect(coreModule, isNotNull);
      expect(coreModule!.type, CatalogNodeType.module);
      expect(coreModule.subjects.every((s) => s.isCompulsory), isTrue);

      final specModule = iamNode.findNodeById('node_iam_specialist');
      expect(specModule, isNotNull);
      expect(specModule!.subjects.every((s) => s.isOptional), isTrue);
    });

    test('getCoursesByCategory returns professional courses', () {
      final profCourses = catalog.getCoursesByCategory(CourseCategory.professional);
      expect(profCourses.length, greaterThan(15));

      expect(profCourses.any((c) => c.id == 'ca_foundation'), isTrue);
      expect(profCourses.any((c) => c.id == 'cs_executive'), isTrue);
      expect(profCourses.any((c) => c.id == 'cma_final'), isTrue);
      expect(profCourses.any((c) => c.id == 'acca_strategic_professional'), isTrue);
      expect(profCourses.any((c) => c.id == 'cfa_level1'), isTrue);
      expect(profCourses.any((c) => c.id == 'frm_part1'), isTrue);
      expect(profCourses.any((c) => c.id == 'actuarial_iam'), isTrue);
    });

    test('searchCourses works for professional courses', () {
      final caResults = catalog.searchCourses('Chartered Accountancy', category: CourseCategory.professional);
      expect(caResults.length, 3);

      final icsiResults = catalog.searchCourses('ICSI', category: CourseCategory.professional);
      expect(icsiResults.length, 3);

      final cfaResults = catalog.searchCourses('CFA', category: CourseCategory.professional);
      expect(cfaResults.length, 3);
    });

    test('Professional courses have curriculum versioning', () {
      final caFound = catalog.getCourseById('ca_foundation')!;
      expect(caFound.catalogVersion, '2025-2026');

      final curr = caFound.getCurriculumByVersion('2025-2026');
      expect(curr, isNotNull);
      expect(curr!.versionCode, '2025-2026');
    });

    test('Subject metadata preserved for professional courses', () {
      final caInt = catalog.getCourseById('ca_intermediate')!;
      final group1 = caInt.activeCurriculum!.structure.first.findNodeById('node_ca_intermediate_group1')!;

      expect(group1.subjects.any((s) => s.type.name == 'groupSpecific'), isTrue);
    });

    test('createStudentSubject works with professional course subject', () {
      final cmaInt = catalog.getCourseById('cma_intermediate')!;
      final costSubj = cmaInt.activeCurriculum!.findSubjectById('cma_int_g1_accounting')!;

      final studentSubject = catalog.createStudentSubject(
        catalogSubject: costSubj,
        courseId: cmaInt.id,
        catalogVersion: cmaInt.catalogVersion,
      );

      expect(studentSubject.name, 'Cost Accounting');
      expect(studentSubject.catalogCourseId, 'cma_intermediate');
      expect(studentSubject.catalogSubjectId, 'cma_int_g1_accounting');
      expect(studentSubject.isCatalogLinked, isTrue);
    });

    test('Professional courses coexist with school and higher ed catalogs', () {
      final schoolCourses = catalog.getCoursesByCategory(CourseCategory.school);
      expect(schoolCourses.length, greaterThan(5));

      final ugCourses = catalog.getCoursesByCategory(CourseCategory.undergraduate);
      expect(ugCourses.length, greaterThan(30));

      final pgCourses = catalog.getCoursesByCategory(CourseCategory.postgraduate);
      expect(pgCourses.length, greaterThan(5));

      final profCourses = catalog.getCoursesByCategory(CourseCategory.professional);
      expect(profCourses.length, greaterThan(15));

      final allCourses = catalog.allCourses;
      expect(allCourses.length, greaterThan(70));
    });

    test('Authority filtering works for professional courses', () {
      final icaiCourses = catalog.searchCourses('ICAI');
      expect(icaiCourses.length, 3);

      final icsiCourses = catalog.searchCourses('ICSI');
      expect(icsiCourses.length, 3);

      final garGarCourses = catalog.searchCourses('GARP');
      expect(garGarCourses.length, 2);
    });

    test('Hierarchy nesting works for complex structures', () {
      final caInt = catalog.getCourseById('ca_intermediate')!;
      final curr = caInt.activeCurriculum!;
      final levelNode = curr.structure.first;

      expect(levelNode.type, CatalogNodeType.level);
      expect(levelNode.children.isNotEmpty, isTrue);

      final group1 = levelNode.children.first;
      expect(group1.type, CatalogNodeType.group);
      expect(group1.subjects.isNotEmpty, isTrue);
    });

    test('Optional papers not marked as compulsory', () {
      final accaSp = catalog.getCourseById('acca_strategic_professional')!;
      final curr = accaSp.activeCurriculum!;
      final levelNode = curr.structure.first;

      final optGroup = levelNode.findNodeById('node_acca_sp_optional')!;
      final allOptional = optGroup.subjects.every((s) => s.isOptional);
      expect(allOptional, isTrue);

      final anyCompulsory = optGroup.subjects.any((s) => s.isCompulsory);
      expect(anyCompulsory, isFalse);
    });

    test('Paper groups identified in FRM correctly', () {
      final frmP1 = catalog.getCourseById('frm_part1')!;
      final curr = frmP1.activeCurriculum!;
      final p1Node = curr.structure.first;

      final paperGroups = p1Node.children.where((c) => c.type == CatalogNodeType.paperGroup).toList();
      expect(paperGroups.length, 2);

      expect(paperGroups[0].name, 'Fundamentals of Risk Management');
      expect(paperGroups[1].name, 'Valuation & Risk Models');
    });
  });
}
