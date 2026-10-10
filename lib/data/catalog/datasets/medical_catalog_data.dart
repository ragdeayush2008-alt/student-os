import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';

abstract final class MedicalCatalogData {
  static const categoryId = 'medical_healthcare';

  static List<CatalogFamily> getFamilies() => [
    _neetFamily,
    _nursingFamily,
    _pharmacyFamily,
    _alliedFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getNEETPrograms(),
    ..._getNursingPrograms(),
    ..._getPharmacyPrograms(),
    ..._getAlliedPrograms(),
  ];

  static const _neetFamily = CatalogFamily(
    id: 'neet',
    categoryId: categoryId,
    title: 'National Eligibility cum Entrance Test',
    shortTitle: 'NEET',
    description: 'NEET UG for MBBS/BDS & NEET PG for Medical Post-Graduation',
    aliases: ['NEET UG', 'NEET PG', 'AIPMT', 'Medical Entrance'],
    isPopular: true,
    programIds: ['neet_ug', 'neet_pg'],
  );

  static List<CatalogProgram> _getNEETPrograms() => [
    CatalogProgram(
      id: 'neet_ug',
      familyId: 'neet',
      categoryId: categoryId,
      title: 'NEET UG',
      authority: 'NTA',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'neet_ug_level',
          programId: 'neet_ug',
          title: 'NEET UG 2026',
          year: '2026',
          papers: [
            CatalogPaper(id: 'neet_phy', programId: 'neet_ug', levelId: 'neet_ug_level', title: 'Physics', order: 1),
            CatalogPaper(id: 'neet_chem', programId: 'neet_ug', levelId: 'neet_ug_level', title: 'Chemistry', order: 2),
            CatalogPaper(id: 'neet_bio', programId: 'neet_ug', levelId: 'neet_ug_level', title: 'Biology', description: 'Botany and Zoology', order: 3),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'neet_pg',
      familyId: 'neet',
      categoryId: categoryId,
      title: 'NEET PG',
      authority: 'NBEMS',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'neet_pg_level',
          programId: 'neet_pg',
          title: 'NEET PG Clinical & Pre-Clinical',
          papers: [
            CatalogPaper(id: 'npg_pre_clinical', programId: 'neet_pg', levelId: 'neet_pg_level', title: 'Pre-Clinical Subjects', description: 'Anatomy, Physiology, Biochemistry'),
            CatalogPaper(id: 'npg_para_clinical', programId: 'neet_pg', levelId: 'neet_pg_level', title: 'Para-Clinical Subjects', description: 'Pathology, Pharmacology, Microbiology, Forensic Medicine, SPM'),
            CatalogPaper(id: 'npg_clinical', programId: 'neet_pg', levelId: 'neet_pg_level', title: 'Clinical Subjects', description: 'General Medicine, General Surgery, OBG, Pediatrics, Orthopedics, ENT, Ophthalmology, Dermatology, Psychiatry, Radiology, Anesthesia'),
          ],
        ),
      ],
    ),
  ];

  static const _nursingFamily = CatalogFamily(
    id: 'nursing',
    categoryId: categoryId,
    title: 'Nursing Entrances',
    shortTitle: 'Nursing',
    programIds: ['bsc_nursing_entrance'],
  );

  static List<CatalogProgram> _getNursingPrograms() => [
    CatalogProgram(
      id: 'bsc_nursing_entrance',
      familyId: 'nursing',
      categoryId: categoryId,
      title: 'B.Sc Nursing Entrance',
      levels: [
        CatalogLevel(
          id: 'nursing_ent_lvl',
          programId: 'bsc_nursing_entrance',
          title: 'General Nursing Entrance',
          papers: [
            CatalogPaper(id: 'nurs_phy', programId: 'bsc_nursing_entrance', levelId: 'nursing_ent_lvl', title: 'Physics'),
            CatalogPaper(id: 'nurs_chem', programId: 'bsc_nursing_entrance', levelId: 'nursing_ent_lvl', title: 'Chemistry'),
            CatalogPaper(id: 'nurs_bio', programId: 'bsc_nursing_entrance', levelId: 'nursing_ent_lvl', title: 'Biology'),
            CatalogPaper(id: 'nurs_apt', programId: 'bsc_nursing_entrance', levelId: 'nursing_ent_lvl', title: 'Nursing Aptitude & English'),
          ],
        ),
      ],
    ),
  ];

  static const _pharmacyFamily = CatalogFamily(
    id: 'pharmacy',
    categoryId: categoryId,
    title: 'Pharmacy Programs',
    shortTitle: 'Pharmacy',
    programIds: ['b_pharm'],
  );

  static List<CatalogProgram> _getPharmacyPrograms() => [
    CatalogProgram(
      id: 'b_pharm',
      familyId: 'pharmacy',
      categoryId: categoryId,
      title: 'B.Pharm (Degree)',
      levels: [
        CatalogLevel(
          id: 'bpharm_lvl',
          programId: 'b_pharm',
          title: 'Pharmacy Core Curriculum',
          papers: [
            CatalogPaper(id: 'bpharm_pharmaceutics', programId: 'b_pharm', levelId: 'bpharm_lvl', title: 'Pharmaceutics'),
            CatalogPaper(id: 'bpharm_chem', programId: 'b_pharm', levelId: 'bpharm_lvl', title: 'Pharmaceutical Chemistry'),
            CatalogPaper(id: 'bpharm_pharmacology', programId: 'b_pharm', levelId: 'bpharm_lvl', title: 'Pharmacology'),
            CatalogPaper(id: 'bpharm_pharmacognosy', programId: 'b_pharm', levelId: 'bpharm_lvl', title: 'Pharmacognosy'),
          ],
        ),
      ],
    ),
  ];

  static const _alliedFamily = CatalogFamily(
    id: 'allied_health',
    categoryId: categoryId,
    title: 'Allied Healthcare Entrances',
    shortTitle: 'Allied Health',
    programIds: ['bpt_entrance'],
  );

  static List<CatalogProgram> _getAlliedPrograms() => [
    CatalogProgram(
      id: 'bpt_entrance',
      familyId: 'allied_health',
      categoryId: categoryId,
      title: 'Physiotherapy (BPT) Entrance',
      levels: [
        CatalogLevel(
          id: 'bpt_lvl',
          programId: 'bpt_entrance',
          title: 'BPT Entrance',
          papers: [
            CatalogPaper(id: 'bpt_phy', programId: 'bpt_entrance', levelId: 'bpt_lvl', title: 'Physics'),
            CatalogPaper(id: 'bpt_chem', programId: 'bpt_entrance', levelId: 'bpt_lvl', title: 'Chemistry'),
            CatalogPaper(id: 'bpt_bio', programId: 'bpt_entrance', levelId: 'bpt_lvl', title: 'Biology'),
          ],
        ),
      ],
    ),
  ];
}
