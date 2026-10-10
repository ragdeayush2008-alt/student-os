import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';

abstract final class ManagementCatalogData {
  static const categoryId = 'management_business';

  static List<CatalogFamily> getFamilies() => [
    _catFamily,
    _xatFamily,
    _snapFamily,
    _otherMbaFamily,
    _mahMbaFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getCATPrograms(),
    ..._getXATPrograms(),
    ..._getSNAPPrograms(),
    ..._getOtherMBAPrograms(),
    ..._getMAHMBAPrograms(),
  ];

  static const _catFamily = CatalogFamily(
    id: 'cat',
    categoryId: categoryId,
    title: 'Common Admission Test',
    shortTitle: 'CAT (IIMs)',
    description: 'CAT for IIMs & premier business schools',
    aliases: ['CAT 2026', 'IIM CAT', 'MBA Entrance'],
    isPopular: true,
    programIds: ['cat_exam'],
  );

  static List<CatalogProgram> _getCATPrograms() => [
    CatalogProgram(
      id: 'cat_exam',
      familyId: 'cat',
      categoryId: categoryId,
      title: 'CAT (Common Admission Test)',
      authority: 'IIMs',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'cat_lvl',
          programId: 'cat_exam',
          title: 'CAT 2026 Sections',
          year: '2026',
          papers: [
            CatalogPaper(id: 'cat_varc', programId: 'cat_exam', levelId: 'cat_lvl', title: 'Verbal Ability & Reading Comprehension (VARC)', order: 1),
            CatalogPaper(id: 'cat_dilr', programId: 'cat_exam', levelId: 'cat_lvl', title: 'Data Interpretation & Logical Reasoning (DILR)', order: 2),
            CatalogPaper(id: 'cat_qa', programId: 'cat_exam', levelId: 'cat_lvl', title: 'Quantitative Aptitude (QA)', order: 3),
          ],
        ),
      ],
    ),
  ];

  static const _xatFamily = CatalogFamily(
    id: 'xat',
    categoryId: categoryId,
    title: 'Xavier Aptitude Test',
    shortTitle: 'XAT (XLRI)',
    programIds: ['xat_exam'],
  );

  static List<CatalogProgram> _getXATPrograms() => [
    CatalogProgram(
      id: 'xat_exam',
      familyId: 'xat',
      categoryId: categoryId,
      title: 'XAT (Xavier Aptitude Test)',
      authority: 'XLRI Jamshedpur',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'xat_lvl',
          programId: 'xat_exam',
          title: 'XAT Sections',
          year: '2026',
          papers: [
            CatalogPaper(id: 'xat_valr', programId: 'xat_exam', levelId: 'xat_lvl', title: 'Verbal Ability & Logical Reasoning (VALR)', order: 1),
            CatalogPaper(id: 'xat_dm', programId: 'xat_exam', levelId: 'xat_lvl', title: 'Decision Making (DM)', order: 2),
            CatalogPaper(id: 'xat_qadi', programId: 'xat_exam', levelId: 'xat_lvl', title: 'Quantitative Aptitude & Data Interpretation (QADI)', order: 3),
            CatalogPaper(id: 'xat_gk', programId: 'xat_exam', levelId: 'xat_lvl', title: 'General Knowledge & Essay', order: 4),
          ],
        ),
      ],
    ),
  ];

  static const _snapFamily = CatalogFamily(
    id: 'snap',
    categoryId: categoryId,
    title: 'Symbiosis National Aptitude Test',
    shortTitle: 'SNAP',
    programIds: ['snap_exam'],
  );

  static List<CatalogProgram> _getSNAPPrograms() => [
    CatalogProgram(
      id: 'snap_exam',
      familyId: 'snap',
      categoryId: categoryId,
      title: 'SNAP (Symbiosis)',
      authority: 'SIU Pune',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'snap_lvl',
          programId: 'snap_exam',
          title: 'SNAP Sections',
          year: '2026',
          papers: [
            CatalogPaper(id: 'snap_ge', programId: 'snap_exam', levelId: 'snap_lvl', title: 'General English (Reading Comprehension, Verbal Reasoning, Verbal Ability)', order: 1),
            CatalogPaper(id: 'snap_alr', programId: 'snap_exam', levelId: 'snap_lvl', title: 'Analytical & Logical Reasoning (A-LR)', order: 2),
            CatalogPaper(id: 'snap_qa_di_ds', programId: 'snap_exam', levelId: 'snap_lvl', title: 'Quantitative, Data Interpretation & Data Sufficiency (QA, DI-DS)', order: 3),
          ],
        ),
      ],
    ),
  ];

  static const _otherMbaFamily = CatalogFamily(
    id: 'other_mba',
    categoryId: categoryId,
    title: 'CMAT, MAT & NMAT',
    shortTitle: 'CMAT / MAT / NMAT',
    programIds: ['cmat_exam', 'nmat_exam'],
  );

  static List<CatalogProgram> _getOtherMBAPrograms() => [
    CatalogProgram(
      id: 'cmat_exam',
      familyId: 'other_mba',
      categoryId: categoryId,
      title: 'CMAT (Common Management Admission Test)',
      authority: 'NTA',
      levels: [
        CatalogLevel(
          id: 'cmat_lvl',
          programId: 'cmat_exam',
          title: 'CMAT Sections',
          papers: [
            CatalogPaper(id: 'cmat_qt_di', programId: 'cmat_exam', levelId: 'cmat_lvl', title: 'Quantitative Techniques & Data Interpretation'),
            CatalogPaper(id: 'cmat_lr', programId: 'cmat_exam', levelId: 'cmat_lvl', title: 'Logical Reasoning'),
            CatalogPaper(id: 'cmat_lc', programId: 'cmat_exam', levelId: 'cmat_lvl', title: 'Language Comprehension'),
            CatalogPaper(id: 'cmat_ga', programId: 'cmat_exam', levelId: 'cmat_lvl', title: 'General Awareness'),
            CatalogPaper(id: 'cmat_ie', programId: 'cmat_exam', levelId: 'cmat_lvl', title: 'Innovation & Entrepreneurship'),
          ],
        ),
      ],
    ),
  ];

  static const _mahMbaFamily = CatalogFamily(
    id: 'mah_mba_cet',
    categoryId: categoryId,
    title: 'MAH MBA / MMS CET',
    shortTitle: 'MAH MBA CET',
    programIds: ['mah_mba_cet_exam'],
  );

  static List<CatalogProgram> _getMAHMBAPrograms() => [
    CatalogProgram(
      id: 'mah_mba_cet_exam',
      familyId: 'mah_mba_cet',
      categoryId: categoryId,
      title: 'MAH MBA / MMS CET',
      authority: 'State CET Cell Maharashtra',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'mah_mba_lvl',
          programId: 'mah_mba_cet_exam',
          title: 'CET Sections',
          papers: [
            CatalogPaper(id: 'mah_mba_logical', programId: 'mah_mba_cet_exam', levelId: 'mah_mba_lvl', title: 'Logical Reasoning'),
            CatalogPaper(id: 'mah_mba_abstract', programId: 'mah_mba_cet_exam', levelId: 'mah_mba_lvl', title: 'Abstract Reasoning'),
            CatalogPaper(id: 'mah_mba_quant', programId: 'mah_mba_cet_exam', levelId: 'mah_mba_lvl', title: 'Quantitative Aptitude'),
            CatalogPaper(id: 'mah_mba_verbal', programId: 'mah_mba_cet_exam', levelId: 'mah_mba_lvl', title: 'Verbal Ability & Reading Comprehension'),
          ],
        ),
      ],
    ),
  ];
}
