import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';

abstract final class LawCatalogData {
  static const categoryId = 'law';

  static List<CatalogFamily> getFamilies() => [
    _clatFamily,
    _ailetFamily,
    _judiciaryFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getCLATPrograms(),
    ..._getAILETPrograms(),
    ..._getJudiciaryPrograms(),
  ];

  static const _clatFamily = CatalogFamily(
    id: 'clat',
    categoryId: categoryId,
    title: 'Common Law Admission Test',
    shortTitle: 'CLAT',
    description: 'CLAT UG for NLUs 5-year LLB and CLAT PG for LLM',
    aliases: ['CLAT UG', 'CLAT PG', 'NLU Entrance', 'Consortium of NLUs'],
    isPopular: true,
    programIds: ['clat_ug', 'clat_pg'],
  );

  static List<CatalogProgram> _getCLATPrograms() => [
    CatalogProgram(
      id: 'clat_ug',
      familyId: 'clat',
      categoryId: categoryId,
      title: 'CLAT UG',
      authority: 'Consortium of NLUs',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'clat_ug_lvl',
          programId: 'clat_ug',
          title: 'CLAT UG 2026',
          year: '2026',
          papers: [
            CatalogPaper(id: 'clat_eng', programId: 'clat_ug', levelId: 'clat_ug_lvl', title: 'English Language', order: 1),
            CatalogPaper(id: 'clat_ca_gk', programId: 'clat_ug', levelId: 'clat_ug_lvl', title: 'Current Affairs including General Knowledge', order: 2),
            CatalogPaper(id: 'clat_legal', programId: 'clat_ug', levelId: 'clat_ug_lvl', title: 'Legal Reasoning', order: 3),
            CatalogPaper(id: 'clat_logical', programId: 'clat_ug', levelId: 'clat_ug_lvl', title: 'Logical Reasoning', order: 4),
            CatalogPaper(id: 'clat_qt', programId: 'clat_ug', levelId: 'clat_ug_lvl', title: 'Quantitative Techniques', order: 5),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'clat_pg',
      familyId: 'clat',
      categoryId: categoryId,
      title: 'CLAT PG (LLM)',
      authority: 'Consortium of NLUs',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'clat_pg_lvl',
          programId: 'clat_pg',
          title: 'CLAT PG 2026',
          year: '2026',
          papers: [
            CatalogPaper(id: 'clat_pg_const', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Constitutional Law', order: 1),
            CatalogPaper(id: 'clat_pg_juris', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Jurisprudence', order: 2),
            CatalogPaper(id: 'clat_pg_admin', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Administrative Law', order: 3),
            CatalogPaper(id: 'clat_pg_contract', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Contract Law', order: 4),
            CatalogPaper(id: 'clat_pg_torts', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Torts', order: 5),
            CatalogPaper(id: 'clat_pg_family', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Family Law', order: 6),
            CatalogPaper(id: 'clat_pg_criminal', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Criminal Law', order: 7),
            CatalogPaper(id: 'clat_pg_property', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Property Law', order: 8),
            CatalogPaper(id: 'clat_pg_company', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Company Law', order: 9),
            CatalogPaper(id: 'clat_pg_pil', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Public International Law', order: 10),
            CatalogPaper(id: 'clat_pg_tax', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Tax Law', order: 11),
            CatalogPaper(id: 'clat_pg_env', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Environmental Law', order: 12),
            CatalogPaper(id: 'clat_pg_labour', programId: 'clat_pg', levelId: 'clat_pg_lvl', title: 'Labour & Industrial Law', order: 13),
          ],
        ),
      ],
    ),
  ];

  static const _ailetFamily = CatalogFamily(
    id: 'ailet',
    categoryId: categoryId,
    title: 'All India Law Entrance Test',
    shortTitle: 'AILET (NLU Delhi)',
    programIds: ['ailet_ug'],
  );

  static List<CatalogProgram> _getAILETPrograms() => [
    CatalogProgram(
      id: 'ailet_ug',
      familyId: 'ailet',
      categoryId: categoryId,
      title: 'AILET UG',
      authority: 'NLU Delhi',
      levels: [
        CatalogLevel(
          id: 'ailet_ug_lvl',
          programId: 'ailet_ug',
          title: 'AILET UG',
          papers: [
            CatalogPaper(id: 'ailet_eng', programId: 'ailet_ug', levelId: 'ailet_ug_lvl', title: 'English Language'),
            CatalogPaper(id: 'ailet_gk', programId: 'ailet_ug', levelId: 'ailet_ug_lvl', title: 'Current Affairs & General Knowledge'),
            CatalogPaper(id: 'ailet_lr', programId: 'ailet_ug', levelId: 'ailet_ug_lvl', title: 'Logical Reasoning'),
          ],
        ),
      ],
    ),
  ];

  static const _judiciaryFamily = CatalogFamily(
    id: 'judiciary',
    categoryId: categoryId,
    title: 'Judicial Services Examination',
    shortTitle: 'Judiciary / Civil Judge',
    programIds: ['state_judiciary_prelims'],
  );

  static List<CatalogProgram> _getJudiciaryPrograms() => [
    CatalogProgram(
      id: 'state_judiciary_prelims',
      familyId: 'judiciary',
      categoryId: categoryId,
      title: 'State Judicial Services (Civil Judge)',
      levels: [
        CatalogLevel(
          id: 'judiciary_prelims_lvl',
          programId: 'state_judiciary_prelims',
          title: 'Preliminary & Mains',
          papers: [
            CatalogPaper(id: 'jud_cpc', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Code of Civil Procedure (CPC)'),
            CatalogPaper(id: 'jud_crpc', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Code of Criminal Procedure (CrPC)'),
            CatalogPaper(id: 'jud_ipc', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Indian Penal Code / BNS'),
            CatalogPaper(id: 'jud_evidence', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Indian Evidence Act / BSA'),
            CatalogPaper(id: 'jud_const', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Constitutional Law of India'),
            CatalogPaper(id: 'jud_contract', programId: 'state_judiciary_prelims', levelId: 'judiciary_prelims_lvl', title: 'Law of Contracts & Specific Relief'),
          ],
        ),
      ],
    ),
  ];
}
