import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/services/course_catalog_service.dart';
import 'package:student_os/data/catalog/master_catalog_registry.dart';

void main() {
  group('Master Catalog 2.0 Hierarchy & Exams Test', () {
    late MasterCatalogRegistry registry;

    setUp(() {
      registry = MasterCatalogRegistry.instance;
      CourseCatalogService.instance.ensureInitialized();
    });

    test('1. Master Categories: All 18 top-level categories exist with correct metadata', () {
      final categories = registry.allCategories;
      expect(categories.length, 18);

      final categoryIds = categories.map((c) => c.id).toSet();
      expect(categoryIds, containsAll([
        'school_boards_olympiads',
        'engineering_technology',
        'medical_healthcare',
        'commerce_accounting_finance',
        'government_job_exams',
        'banking_financial_recruitment',
        'management_business',
        'law',
        'science_university_entrance',
        'teaching_education',
        'research_net_exams',
        'defence',
        'design',
        'architecture_planning',
        'agriculture',
        'postgraduate_entrance',
        'professional_certifications',
        'other_career_upskilling',
      ]));

      // Verify category attributes
      final schoolCat = registry.getCategoryById('school_boards_olympiads');
      expect(schoolCat, isNotNull);
      expect(schoolCat!.title, 'School, Boards & Olympiads');
      expect(schoolCat.isPopular, isTrue);
    });

    test('2. CA 2026: Foundation has exact 4 official 2026 papers', () {
      final caFoundation = registry.getProgramById('ca_foundation');
      expect(caFoundation, isNotNull);
      expect(caFoundation!.authority, 'ICAI');
      expect(caFoundation.defaultYear, '2026');

      final resolved = registry.resolvePapers(programId: 'ca_foundation');
      final papers = resolved['compulsory']!;
      expect(papers.length, 4);

      expect(papers[0].title, 'Accounting');
      expect(papers[1].title, 'Business Laws');
      expect(papers[2].title, 'Quantitative Aptitude');
      expect(papers[2].description, contains('Business Mathematics'));
      expect(papers[2].description, contains('Logical Reasoning'));
      expect(papers[2].description, contains('Statistics'));
      expect(papers[3].title, 'Business Economics');
    });

    test('3. CA 2026: Intermediate and Final Group I & II structures', () {
      final caInter = registry.getProgramById('ca_intermediate');
      expect(caInter, isNotNull);
      expect(caInter!.levels.first.children.length, 2);

      final g1 = caInter.levels.first.children.firstWhere((c) => c.title == 'Group I');
      expect(g1.papers.length, 3);
      expect(g1.papers.map((p) => p.title), containsAll([
        'Advanced Accounting',
        'Corporate and Other Laws',
        'Taxation',
      ]));

      final g2 = caInter.levels.first.children.firstWhere((c) => c.title == 'Group II');
      expect(g2.papers.length, 3);
      expect(g2.papers.map((p) => p.title), containsAll([
        'Cost and Management Accounting',
        'Auditing and Ethics',
        'Financial Management and Strategic Management',
      ]));

      final caFinal = registry.getProgramById('ca_final');
      expect(caFinal, isNotNull);
      final finalG1 = caFinal!.levels.first.children.firstWhere((c) => c.title == 'Group I');
      expect(finalG1.papers.length, 3);
      expect(finalG1.papers.map((p) => p.title), containsAll([
        'Financial Reporting',
        'Advanced Financial Management',
        'Advanced Auditing, Assurance and Professional Ethics',
      ]));

      final finalG2 = caFinal.levels.first.children.firstWhere((c) => c.title == 'Group II');
      expect(finalG2.papers.length, 3);
      expect(finalG2.papers.map((p) => p.title), containsAll([
        'Direct Tax Laws & International Taxation',
        'Indirect Tax Laws',
        'Integrated Business Solutions',
      ]));
    });

    test('4. Engineering: JEE Main and JEE Advanced', () {
      final jeeMain = registry.getProgramById('jee_main');
      expect(jeeMain, isNotNull);
      expect(jeeMain!.authority, 'NTA');
      expect(jeeMain.defaultYear, '2026');

      final resolved = registry.resolvePapers(programId: 'jee_main');
      final papers = resolved['compulsory']!;
      expect(papers.length, 3);
      expect(papers.map((p) => p.title), containsAll(['Physics', 'Chemistry', 'Mathematics']));

      final jeeAdv = registry.getProgramById('jee_advanced');
      expect(jeeAdv, isNotNull);
      expect(jeeAdv!.authority, 'IITs');
    });

    test('5. GATE 2026: Multi-paper structure with 20+ disciplines', () {
      final gate = registry.getProgramById('gate_2026');
      expect(gate, isNotNull);
      expect(gate!.defaultYear, '2026');
      expect(gate.levels.length, greaterThanOrEqualTo(20));

      final csLevel = gate.levels.firstWhere((l) => l.code == 'CS_IT');
      expect(csLevel.papers.length, 2);
      expect(csLevel.papers.any((p) => p.title.contains('General Aptitude')), isTrue);
      expect(csLevel.papers.any((p) => p.title.contains('Computer Science')), isTrue);

      final daLevel = gate.levels.firstWhere((l) => l.code == 'DA');
      expect(daLevel.title, contains('Data Science & Artificial Intelligence'));

      final eeLevel = gate.levels.firstWhere((l) => l.code == 'EE');
      expect(eeLevel.title, contains('Electrical Engineering'));

      final meLevel = gate.levels.firstWhere((l) => l.code == 'ME');
      expect(meLevel.title, contains('Mechanical Engineering'));

      final ceLevel = gate.levels.firstWhere((l) => l.code == 'CE');
      expect(ceLevel.title, contains('Civil Engineering'));
    });

    test('6. Medical: NEET UG 2026 and NEET PG', () {
      final neetUg = registry.getProgramById('neet_ug');
      expect(neetUg, isNotNull);
      expect(neetUg!.authority, 'NTA');
      expect(neetUg.defaultYear, '2026');

      final resolved = registry.resolvePapers(programId: 'neet_ug');
      final papers = resolved['compulsory']!;
      expect(papers.length, 3);
      expect(papers.map((p) => p.title), containsAll(['Physics', 'Chemistry', 'Biology']));

      final neetPg = registry.getProgramById('neet_pg');
      expect(neetPg, isNotNull);
      expect(neetPg!.levels.first.papers.length, 3);
    });

    test('7. Law: CLAT UG 2026 and CLAT PG 2026', () {
      final clatUg = registry.getProgramById('clat_ug');
      expect(clatUg, isNotNull);
      expect(clatUg!.authority, 'Consortium of NLUs');
      expect(clatUg.defaultYear, '2026');

      final resolved = registry.resolvePapers(programId: 'clat_ug');
      final papers = resolved['compulsory']!;
      expect(papers.length, 5);
      expect(papers.map((p) => p.title), containsAll([
        'English Language',
        'Current Affairs including General Knowledge',
        'Legal Reasoning',
        'Logical Reasoning',
        'Quantitative Techniques',
      ]));

      final clatPg = registry.getProgramById('clat_pg');
      expect(clatPg, isNotNull);
      final pgPapers = clatPg!.levels.first.papers;
      expect(pgPapers.length, greaterThanOrEqualTo(10));
      expect(pgPapers.map((p) => p.title), containsAll([
        'Constitutional Law',
        'Jurisprudence',
        'Administrative Law',
        'Contract Law',
        'Torts',
        'Criminal Law',
        'Company Law',
      ]));
    });

    test('8. University Entrance: CUET UG 2026 multi-section structure', () {
      final cuetUg = registry.getProgramById('cuet_ug_exam');
      expect(cuetUg, isNotNull);
      expect(cuetUg!.authority, 'NTA');
      expect(cuetUg.defaultYear, '2026');

      final root = cuetUg.levels.first;
      expect(root.children.length, 3);

      final langSection = root.children.firstWhere((c) => c.title.contains('Languages'));
      expect(langSection.papers.length, greaterThanOrEqualTo(13));
      expect(langSection.papers.map((p) => p.title), containsAll(['English', 'Hindi', 'Marathi', 'Tamil']));

      final domainSection = root.children.firstWhere((c) => c.title.contains('Domain Specific'));
      expect(domainSection.papers.length, greaterThanOrEqualTo(20));
      expect(domainSection.papers.map((p) => p.title), containsAll([
        'Accountancy / Book Keeping',
        'Physics',
        'Chemistry',
        'Mathematics / Applied Mathematics',
        'Economics / Business Economics',
        'Political Science',
        'History',
      ]));

      final gatSection = root.children.firstWhere((c) => c.title.contains('General Test'));
      expect(gatSection.papers.first.title, contains('General Aptitude Test'));
    });

    test('9. Management: CAT, XAT, SNAP', () {
      final cat = registry.getProgramById('cat_exam');
      expect(cat, isNotNull);
      final catPapers = cat!.levels.first.papers;
      expect(catPapers.length, 3);
      expect(catPapers.map((p) => p.title), containsAll([
        'Verbal Ability & Reading Comprehension (VARC)',
        'Data Interpretation & Logical Reasoning (DILR)',
        'Quantitative Aptitude (QA)',
      ]));

      final xat = registry.getProgramById('xat_exam');
      expect(xat, isNotNull);
      expect(xat!.levels.first.papers.length, 4);
      expect(xat.levels.first.papers.map((p) => p.title), contains('Decision Making (DM)'));

      final snap = registry.getProgramById('snap_exam');
      expect(snap, isNotNull);
      expect(snap!.levels.first.papers.length, 3);
    });

    test('10. Finance Certifications: CFA 2026, FRM, Actuarial, ACCA, CS', () {
      // CFA Level I 2026
      final cfa1 = registry.getProgramById('cfa_level1');
      expect(cfa1, isNotNull);
      expect(cfa1!.defaultYear, '2026');
      expect(cfa1.levels.first.papers.length, 10);
      expect(cfa1.levels.first.papers.map((p) => p.title), containsAll([
        'Ethical and Professional Standards',
        'Quantitative Methods',
        'Economics',
        'Financial Statement Analysis',
        'Corporate Issuers',
      ]));

      // CFA Level III 2026 Pathways
      final cfa3 = registry.getProgramById('cfa_level3');
      expect(cfa3, isNotNull);
      expect(cfa3!.levels.first.papers.any((p) => p.title.contains('Portfolio Management Pathway')), isTrue);
      expect(cfa3.levels.first.papers.any((p) => p.title.contains('Private Markets Pathway')), isTrue);

      // FRM
      final frm1 = registry.getProgramById('frm_part1');
      expect(frm1, isNotNull);
      expect(frm1!.levels.first.papers.length, 4);

      // Actuarial
      final act = registry.getProgramById('actuarial_ifoa_iai');
      expect(act, isNotNull);
      expect(act!.levels.first.children.any((c) => c.title.contains('Core Principles')), isTrue);
      expect(act.levels.first.children.any((c) => c.title.contains('Specialist Principles')), isTrue);

      // ACCA
      final acca = registry.getProgramById('acca_strategic_professional');
      expect(acca, isNotNull);
      expect(acca!.levels.first.children.length, 2);

      // CS
      final csExec = registry.getProgramById('cs_executive');
      expect(csExec, isNotNull);
      expect(csExec!.levels.first.children.length, 2);
    });

    test('11. Government & Recruitment: UPSC, SSC, Banking, Defence, Teaching, UGC NET', () {
      // UPSC CSE
      final upsc = registry.getProgramById('upsc_cse');
      expect(upsc, isNotNull);
      expect(upsc!.levels.any((l) => l.title.contains('Preliminary')), isTrue);
      expect(upsc.levels.any((l) => l.title.contains('Main')), isTrue);

      // SSC CGL
      final ssc = registry.getProgramById('ssc_cgl');
      expect(ssc, isNotNull);
      expect(ssc!.levels.any((l) => l.title.contains('Tier I')), isTrue);
      expect(ssc.levels.any((l) => l.title.contains('Tier II')), isTrue);

      // Banking
      final ibps = registry.getProgramById('ibps_po');
      expect(ibps, isNotNull);
      expect(ibps!.levels.first.papers.length, 3);

      // Defence
      final nda = registry.getProgramById('nda_exam');
      expect(nda, isNotNull);
      expect(nda!.levels.first.papers.length, 2);

      // UGC NET
      final ugcNet = registry.getProgramById('ugc_net_exam');
      expect(ugcNet, isNotNull);
      expect(ugcNet!.levels.length, greaterThanOrEqualTo(10));
      expect(ugcNet.levels.any((l) => l.title.contains('Economics')), isTrue);
      expect(ugcNet.levels.any((l) => l.title.contains('Computer Science')), isTrue);
    });

    test('12. Fast Search across titles, codes, aliases, and subjects', () {
      expect(registry.search('CA Foundation').isNotEmpty, isTrue);
      expect(registry.search('JEE').length, greaterThanOrEqualTo(2));
      expect(registry.search('NEET').length, greaterThanOrEqualTo(2));
      expect(registry.search('UPSC').length, greaterThanOrEqualTo(1));
      expect(registry.search('SSC CGL').isNotEmpty, isTrue);
      expect(registry.search('CUET').length, greaterThanOrEqualTo(1));
      expect(registry.search('Accounting').isNotEmpty, isTrue);
      expect(registry.search('Data Science').isNotEmpty, isTrue);
    });
  });
}
