import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_node.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';
import '../../models/catalog/catalog_subject.dart';

abstract final class CommerceFinanceCatalogData {
  static const categoryId = 'commerce_accounting_finance';

  static List<CatalogFamily> getFamilies() => [
    _caFamily,
    _csFamily,
    _cmaFamily,
    _accaFamily,
    _cfaFamily,
    _frmFamily,
    _actuarialFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getCAPrograms(),
    ..._getCSPrograms(),
    ..._getCMAPrograms(),
    ..._getACCAPrograms(),
    ..._getCFAPrograms(),
    ..._getFRMPrograms(),
    ..._getActuarialPrograms(),
  ];

  // ─── CHARTERED ACCOUNTANCY (CA) ──────────────────────────────────────────

  static const _caFamily = CatalogFamily(
    id: 'ca',
    categoryId: categoryId,
    title: 'Chartered Accountancy',
    shortTitle: 'CA (ICAI)',
    description: 'CA Foundation, Intermediate & Final by ICAI',
    aliases: ['Chartered Accountant', 'ICAI', 'CA 2026'],
    isPopular: true,
    programIds: ['ca_foundation', 'ca_intermediate', 'ca_final'],
  );

  static List<CatalogProgram> _getCAPrograms() {
    return [
      CatalogProgram(
        id: 'ca_foundation',
        familyId: 'ca',
        categoryId: categoryId,
        title: 'CA Foundation',
        authority: 'ICAI',
        defaultYear: '2026',
        availableYears: const ['2026'],
        levels: [
          CatalogLevel(
            id: 'ca_f_level',
            programId: 'ca_foundation',
            title: 'Foundation Level',
            year: '2026',
            papers: [
              CatalogPaper(id: 'ca_f_2026_acc', programId: 'ca_foundation', levelId: 'ca_f_level', title: 'Accounting', order: 1),
              CatalogPaper(id: 'ca_f_2026_law', programId: 'ca_foundation', levelId: 'ca_f_level', title: 'Business Laws', order: 2),
              CatalogPaper(id: 'ca_f_2026_qa', programId: 'ca_foundation', levelId: 'ca_f_level', title: 'Quantitative Aptitude', description: 'Business Mathematics, Logical Reasoning, Statistics', order: 3),
              CatalogPaper(id: 'ca_f_2026_eco', programId: 'ca_foundation', levelId: 'ca_f_level', title: 'Business Economics', order: 4),
            ],
          ),
        ],
      ),
      CatalogProgram(
        id: 'ca_intermediate',
        familyId: 'ca',
        categoryId: categoryId,
        title: 'CA Intermediate',
        authority: 'ICAI',
        defaultYear: '2026',
        levels: [
          CatalogLevel(
            id: 'ca_int_level',
            programId: 'ca_intermediate',
            title: 'Intermediate Level',
            year: '2026',
            children: [
              CatalogLevel(
                id: 'ca_int_g1',
                programId: 'ca_intermediate',
                title: 'Group I',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'ca_int_g1_acc', programId: 'ca_intermediate', levelId: 'ca_int_g1', title: 'Advanced Accounting', type: SubjectRequirementType.groupSpecific, order: 1),
                  CatalogPaper(id: 'ca_int_g1_law', programId: 'ca_intermediate', levelId: 'ca_int_g1', title: 'Corporate and Other Laws', type: SubjectRequirementType.groupSpecific, order: 2),
                  CatalogPaper(id: 'ca_int_g1_tax', programId: 'ca_intermediate', levelId: 'ca_int_g1', title: 'Taxation', type: SubjectRequirementType.groupSpecific, order: 3),
                ],
              ),
              CatalogLevel(
                id: 'ca_int_g2',
                programId: 'ca_intermediate',
                title: 'Group II',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'ca_int_g2_cost', programId: 'ca_intermediate', levelId: 'ca_int_g2', title: 'Cost and Management Accounting', type: SubjectRequirementType.groupSpecific, order: 4),
                  CatalogPaper(id: 'ca_int_g2_audit', programId: 'ca_intermediate', levelId: 'ca_int_g2', title: 'Auditing and Ethics', type: SubjectRequirementType.groupSpecific, order: 5),
                  CatalogPaper(id: 'ca_int_g2_fm', programId: 'ca_intermediate', levelId: 'ca_int_g2', title: 'Financial Management and Strategic Management', type: SubjectRequirementType.groupSpecific, order: 6),
                ],
              ),
            ],
          ),
        ],
      ),
      CatalogProgram(
        id: 'ca_final',
        familyId: 'ca',
        categoryId: categoryId,
        title: 'CA Final',
        authority: 'ICAI',
        defaultYear: '2026',
        levels: [
          CatalogLevel(
            id: 'ca_final_level',
            programId: 'ca_final',
            title: 'Final Level',
            year: '2026',
            children: [
              CatalogLevel(
                id: 'ca_final_g1',
                programId: 'ca_final',
                title: 'Group I',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'ca_final_g1_fr', programId: 'ca_final', levelId: 'ca_final_g1', title: 'Financial Reporting', type: SubjectRequirementType.groupSpecific, order: 1),
                  CatalogPaper(id: 'ca_final_g1_afm', programId: 'ca_final', levelId: 'ca_final_g1', title: 'Advanced Financial Management', type: SubjectRequirementType.groupSpecific, order: 2),
                  CatalogPaper(id: 'ca_final_g1_audit', programId: 'ca_final', levelId: 'ca_final_g1', title: 'Advanced Auditing, Assurance and Professional Ethics', type: SubjectRequirementType.groupSpecific, order: 3),
                ],
              ),
              CatalogLevel(
                id: 'ca_final_g2',
                programId: 'ca_final',
                title: 'Group II',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'ca_final_g2_dt', programId: 'ca_final', levelId: 'ca_final_g2', title: 'Direct Tax Laws & International Taxation', type: SubjectRequirementType.groupSpecific, order: 4),
                  CatalogPaper(id: 'ca_final_g2_idt', programId: 'ca_final', levelId: 'ca_final_g2', title: 'Indirect Tax Laws', type: SubjectRequirementType.groupSpecific, order: 5),
                  CatalogPaper(id: 'ca_final_g2_ibs', programId: 'ca_final', levelId: 'ca_final_g2', title: 'Integrated Business Solutions', type: SubjectRequirementType.groupSpecific, order: 6),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ─── COMPANY SECRETARY (CS) ─────────────────────────────────────────────

  static const _csFamily = CatalogFamily(
    id: 'cs',
    categoryId: categoryId,
    title: 'Company Secretary',
    shortTitle: 'CS (ICSI)',
    aliases: ['ICSI', 'CS Executive', 'CSEET'],
    programIds: ['cs_cseet', 'cs_executive', 'cs_professional'],
  );

  static List<CatalogProgram> _getCSPrograms() {
    return [
      CatalogProgram(
        id: 'cs_cseet',
        familyId: 'cs',
        categoryId: categoryId,
        title: 'CS CSEET',
        authority: 'ICSI',
        levels: [
          CatalogLevel(
            id: 'cs_cseet_level',
            programId: 'cs_cseet',
            title: 'CSEET',
            papers: [
              CatalogPaper(id: 'cs_c_1', programId: 'cs_cseet', levelId: 'cs_cseet_level', title: 'Business Communication'),
              CatalogPaper(id: 'cs_c_2', programId: 'cs_cseet', levelId: 'cs_cseet_level', title: 'Legal Aptitude and Logical Reasoning'),
              CatalogPaper(id: 'cs_c_3', programId: 'cs_cseet', levelId: 'cs_cseet_level', title: 'Economic and Business Environment'),
              CatalogPaper(id: 'cs_c_4', programId: 'cs_cseet', levelId: 'cs_cseet_level', title: 'Current Affairs, Presentation and Communication Skills'),
            ],
          ),
        ],
      ),
      CatalogProgram(
        id: 'cs_executive',
        familyId: 'cs',
        categoryId: categoryId,
        title: 'CS Executive',
        authority: 'ICSI',
        defaultYear: '2022',
        levels: [
          CatalogLevel(
            id: 'cs_exec_level',
            programId: 'cs_executive',
            title: 'Executive Level',
            children: [
              CatalogLevel(
                id: 'cs_e_g1',
                programId: 'cs_executive',
                title: 'Group 1',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'cs_e_g1_1', programId: 'cs_executive', levelId: 'cs_e_g1', title: 'Jurisprudence, Interpretation and General Laws', type: SubjectRequirementType.groupSpecific),
                  CatalogPaper(id: 'cs_e_g1_2', programId: 'cs_executive', levelId: 'cs_e_g1', title: 'Company Law and Practice', type: SubjectRequirementType.groupSpecific),
                  CatalogPaper(id: 'cs_e_g1_3', programId: 'cs_executive', levelId: 'cs_e_g1', title: 'Setting Up of Business, Industrial and Labour Laws', type: SubjectRequirementType.groupSpecific),
                  CatalogPaper(id: 'cs_e_g1_4', programId: 'cs_executive', levelId: 'cs_e_g1', title: 'Corporate Accounting and Financial Management', type: SubjectRequirementType.groupSpecific),
                ],
              ),
              CatalogLevel(
                id: 'cs_e_g2',
                programId: 'cs_executive',
                title: 'Group 2',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(id: 'cs_e_g2_1', programId: 'cs_executive', levelId: 'cs_e_g2', title: 'Capital Market and Securities Laws', type: SubjectRequirementType.groupSpecific),
                  CatalogPaper(id: 'cs_e_g2_2', programId: 'cs_executive', levelId: 'cs_e_g2', title: 'Economic, Commercial and Intellectual Property Laws', type: SubjectRequirementType.groupSpecific),
                  CatalogPaper(id: 'cs_e_g2_3', programId: 'cs_executive', levelId: 'cs_e_g2', title: 'Tax Laws and Practice', type: SubjectRequirementType.groupSpecific),
                ],
              ),
            ],
          ),
        ],
      ),
      CatalogProgram(
        id: 'cs_professional',
        familyId: 'cs',
        categoryId: categoryId,
        title: 'CS Professional',
        authority: 'ICSI',
        levels: [
          CatalogLevel(
            id: 'cs_prof_level',
            programId: 'cs_professional',
            title: 'Professional Level',
            papers: [
              CatalogPaper(id: 'cs_p_1', programId: 'cs_professional', levelId: 'cs_prof_level', title: 'Environmental, Social and Governance (ESG)'),
              CatalogPaper(id: 'cs_p_2', programId: 'cs_professional', levelId: 'cs_prof_level', title: 'Drafting, Pleadings and Appearances'),
              CatalogPaper(id: 'cs_p_3', programId: 'cs_professional', levelId: 'cs_prof_level', title: 'Compliance Management, Audit and Due Diligence'),
            ],
          ),
        ],
      ),
    ];
  }

  // ─── CMA ─────────────────────────────────────────────────────────────

  static const _cmaFamily = CatalogFamily(
    id: 'cma',
    categoryId: categoryId,
    title: 'Cost & Management Accountancy',
    shortTitle: 'CMA (ICMAI)',
    programIds: ['cma_foundation', 'cma_intermediate', 'cma_final'],
  );

  static List<CatalogProgram> _getCMAPrograms() => [
    CatalogProgram(
      id: 'cma_foundation',
      familyId: 'cma',
      categoryId: categoryId,
      title: 'CMA Foundation',
      levels: [
        CatalogLevel(
          id: 'cma_f_level',
          programId: 'cma_foundation',
          title: 'Foundation Level',
          papers: [
            CatalogPaper(id: 'cma_f_1', programId: 'cma_foundation', levelId: 'cma_f_level', title: 'Fundamentals of Business Laws and Business Communication'),
            CatalogPaper(id: 'cma_f_2', programId: 'cma_foundation', levelId: 'cma_f_level', title: 'Fundamentals of Financial and Cost Accounting'),
            CatalogPaper(id: 'cma_f_3', programId: 'cma_foundation', levelId: 'cma_f_level', title: 'Fundamentals of Business Mathematics and Statistics'),
            CatalogPaper(id: 'cma_f_4', programId: 'cma_foundation', levelId: 'cma_f_level', title: 'Fundamentals of Business Economics and Management'),
          ],
        )
      ]
    ),
    CatalogProgram(
      id: 'cma_intermediate',
      familyId: 'cma',
      categoryId: categoryId,
      title: 'CMA Intermediate',
      levels: [
        CatalogLevel(
          id: 'cma_int_level',
          programId: 'cma_intermediate',
          title: 'Intermediate Level',
          papers: [
            CatalogPaper(id: 'cma_int_1', programId: 'cma_intermediate', levelId: 'cma_int_level', title: 'Business Laws and Ethics'),
            CatalogPaper(id: 'cma_int_2', programId: 'cma_intermediate', levelId: 'cma_int_level', title: 'Financial Accounting'),
          ]
        )
      ]
    ),
    CatalogProgram(
      id: 'cma_final',
      familyId: 'cma',
      categoryId: categoryId,
      title: 'CMA Final',
      levels: [
        CatalogLevel(
          id: 'cma_fin_level',
          programId: 'cma_final',
          title: 'Final Level',
          papers: [
            CatalogPaper(id: 'cma_fin_1', programId: 'cma_final', levelId: 'cma_fin_level', title: 'Corporate and Economic Laws'),
            CatalogPaper(id: 'cma_fin_2', programId: 'cma_final', levelId: 'cma_fin_level', title: 'Strategic Financial Management'),
          ]
        )
      ]
    ),
  ];

  // ─── ACCA ────────────────────────────────────────────────────────────

  static const _accaFamily = CatalogFamily(
    id: 'acca',
    categoryId: categoryId,
    title: 'ACCA',
    shortTitle: 'ACCA',
    programIds: ['acca_applied_knowledge', 'acca_applied_skills', 'acca_strategic_professional'],
  );

  static List<CatalogProgram> _getACCAPrograms() => [
    CatalogProgram(
      id: 'acca_applied_knowledge',
      familyId: 'acca',
      categoryId: categoryId,
      title: 'ACCA Applied Knowledge',
      levels: [
        CatalogLevel(
          id: 'acca_ak_lvl',
          programId: 'acca_applied_knowledge',
          title: 'Applied Knowledge',
          papers: [
            CatalogPaper(id: 'acca_bt', programId: 'acca_applied_knowledge', levelId: 'acca_ak_lvl', title: 'Business and Technology (BT)'),
            CatalogPaper(id: 'acca_ma', programId: 'acca_applied_knowledge', levelId: 'acca_ak_lvl', title: 'Management Accounting (MA)'),
            CatalogPaper(id: 'acca_fa', programId: 'acca_applied_knowledge', levelId: 'acca_ak_lvl', title: 'Financial Accounting (FA)'),
          ],
        )
      ]
    ),
    CatalogProgram(
      id: 'acca_applied_skills',
      familyId: 'acca',
      categoryId: categoryId,
      title: 'ACCA Applied Skills',
      levels: [
        CatalogLevel(
          id: 'acca_as_lvl',
          programId: 'acca_applied_skills',
          title: 'Applied Skills',
          papers: [
            CatalogPaper(id: 'acca_lw', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Corporate and Business Law (LW)'),
            CatalogPaper(id: 'acca_pm', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Performance Management (PM)'),
            CatalogPaper(id: 'acca_tx', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Taxation (TX)'),
            CatalogPaper(id: 'acca_fr', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Financial Reporting (FR)'),
            CatalogPaper(id: 'acca_aa', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Audit and Assurance (AA)'),
            CatalogPaper(id: 'acca_fm', programId: 'acca_applied_skills', levelId: 'acca_as_lvl', title: 'Financial Management (FM)'),
          ],
        )
      ]
    ),
    CatalogProgram(
      id: 'acca_strategic_professional',
      familyId: 'acca',
      categoryId: categoryId,
      title: 'ACCA Strategic Professional',
      levels: [
        CatalogLevel(
          id: 'acca_sp_lvl',
          programId: 'acca_strategic_professional',
          title: 'Strategic Professional',
          children: [
            CatalogLevel(
              id: 'acca_sp_essentials',
              programId: 'acca_strategic_professional',
              title: 'Essentials (Compulsory)',
              type: CatalogNodeType.group,
              papers: [
                CatalogPaper(id: 'acca_sbl', programId: 'acca_strategic_professional', levelId: 'acca_sp_essentials', title: 'Strategic Business Leader (SBL)'),
                CatalogPaper(id: 'acca_sbr', programId: 'acca_strategic_professional', levelId: 'acca_sp_essentials', title: 'Strategic Business Reporting (SBR)'),
              ],
            ),
            CatalogLevel(
              id: 'acca_sp_options',
              programId: 'acca_strategic_professional',
              title: 'Options (Choose 2)',
              type: CatalogNodeType.group,
              papers: [
                CatalogPaper(id: 'acca_afm', programId: 'acca_strategic_professional', levelId: 'acca_sp_options', title: 'Advanced Financial Management (AFM)', isOptional: true),
                CatalogPaper(id: 'acca_apm', programId: 'acca_strategic_professional', levelId: 'acca_sp_options', title: 'Advanced Performance Management (APM)', isOptional: true),
                CatalogPaper(id: 'acca_atx', programId: 'acca_strategic_professional', levelId: 'acca_sp_options', title: 'Advanced Taxation (ATX)', isOptional: true),
                CatalogPaper(id: 'acca_aaa', programId: 'acca_strategic_professional', levelId: 'acca_sp_options', title: 'Advanced Audit and Assurance (AAA)', isOptional: true),
              ],
            ),
          ]
        )
      ]
    ),
  ];

  // ─── CFA ─────────────────────────────────────────────────────────────

  static const _cfaFamily = CatalogFamily(
    id: 'cfa',
    categoryId: categoryId,
    title: 'CFA Institute',
    shortTitle: 'CFA',
    programIds: ['cfa_level1', 'cfa_level2', 'cfa_level3'],
  );

  static List<CatalogProgram> _getCFAPrograms() => [
    CatalogProgram(
      id: 'cfa_level1',
      familyId: 'cfa',
      categoryId: categoryId,
      title: 'CFA Level I',
      authority: 'CFA Institute',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'cfa_l1_lvl',
          programId: 'cfa_level1',
          title: 'Level I 2026',
          year: '2026',
          papers: [
            CatalogPaper(id: 'cfa1_1', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Ethical and Professional Standards'),
            CatalogPaper(id: 'cfa1_2', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Quantitative Methods'),
            CatalogPaper(id: 'cfa1_3', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Economics'),
            CatalogPaper(id: 'cfa1_4', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Financial Statement Analysis'),
            CatalogPaper(id: 'cfa1_5', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Corporate Issuers'),
            CatalogPaper(id: 'cfa1_6', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Equity Investments'),
            CatalogPaper(id: 'cfa1_7', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Fixed Income'),
            CatalogPaper(id: 'cfa1_8', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Derivatives'),
            CatalogPaper(id: 'cfa1_9', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Alternative Investments'),
            CatalogPaper(id: 'cfa1_10', programId: 'cfa_level1', levelId: 'cfa_l1_lvl', title: 'Portfolio Management'),
          ]
        )
      ]
    ),
    CatalogProgram(
      id: 'cfa_level2',
      familyId: 'cfa',
      categoryId: categoryId,
      title: 'CFA Level II',
      authority: 'CFA Institute',
      levels: [
        CatalogLevel(
          id: 'cfa_l2_lvl',
          programId: 'cfa_level2',
          title: 'Level II',
          papers: [
            CatalogPaper(id: 'cfa2_1', programId: 'cfa_level2', levelId: 'cfa_l2_lvl', title: 'Ethical and Professional Standards'),
            CatalogPaper(id: 'cfa2_10', programId: 'cfa_level2', levelId: 'cfa_l2_lvl', title: 'Portfolio Management and Wealth Planning'),
          ]
        )
      ]
    ),
    CatalogProgram(
      id: 'cfa_level3',
      familyId: 'cfa',
      categoryId: categoryId,
      title: 'CFA Level III',
      authority: 'CFA Institute',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'cfa_l3_lvl',
          programId: 'cfa_level3',
          title: 'Level III 2026',
          year: '2026',
          papers: [
            CatalogPaper(id: 'cfa3_1', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Ethical and Professional Standards', type: SubjectRequirementType.compulsory),
            CatalogPaper(id: 'cfa3_2', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Asset Allocation', type: SubjectRequirementType.compulsory),
            CatalogPaper(id: 'cfa3_3', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Portfolio Construction', type: SubjectRequirementType.compulsory),
            CatalogPaper(id: 'cfa3_4', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Performance Measurement', type: SubjectRequirementType.compulsory),
            CatalogPaper(id: 'cfa3_5', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Derivatives & Risk Management', type: SubjectRequirementType.compulsory),
            CatalogPaper(id: 'cfa3_p1', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Portfolio Management Pathway', isOptional: true),
            CatalogPaper(id: 'cfa3_p2', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Private Markets Pathway', isOptional: true),
            CatalogPaper(id: 'cfa3_p3', programId: 'cfa_level3', levelId: 'cfa_l3_lvl', title: 'Private Wealth Pathway', isOptional: true),
          ]
        )
      ]
    ),
  ];

  // ─── FRM ──────────────────────────────────────────────────────────────

  static const _frmFamily = CatalogFamily(
    id: 'frm',
    categoryId: categoryId,
    title: 'Financial Risk Manager',
    shortTitle: 'FRM (GARP)',
    programIds: ['frm_part1', 'frm_part2'],
  );

  static List<CatalogProgram> _getFRMPrograms() => [
    CatalogProgram(
      id: 'frm_part1',
      familyId: 'frm',
      categoryId: categoryId,
      title: 'FRM Part I',
      authority: 'GARP',
      levels: [
        CatalogLevel(
          id: 'frm_p1_lvl',
          programId: 'frm_part1',
          title: 'Part I',
          papers: [
            CatalogPaper(id: 'frm1_1', programId: 'frm_part1', levelId: 'frm_p1_lvl', title: 'Foundations of Risk Management'),
            CatalogPaper(id: 'frm1_2', programId: 'frm_part1', levelId: 'frm_p1_lvl', title: 'Quantitative Analysis'),
            CatalogPaper(id: 'frm1_3', programId: 'frm_part1', levelId: 'frm_p1_lvl', title: 'Financial Markets and Products'),
            CatalogPaper(id: 'frm1_4', programId: 'frm_part1', levelId: 'frm_p1_lvl', title: 'Valuation and Risk Models'),
          ]
        )
      ]
    ),
    CatalogProgram(
      id: 'frm_part2',
      familyId: 'frm',
      categoryId: categoryId,
      title: 'FRM Part II',
      authority: 'GARP',
      levels: [
        CatalogLevel(
          id: 'frm_p2_lvl',
          programId: 'frm_part2',
          title: 'Part II',
          papers: [
            CatalogPaper(id: 'frm2_1', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Market Risk Measurement and Management'),
            CatalogPaper(id: 'frm2_2', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Credit Risk Measurement and Management'),
            CatalogPaper(id: 'frm2_3', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Operational Risk and Resilience'),
            CatalogPaper(id: 'frm2_4', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Liquidity and Treasury Risk Measurement and Management'),
            CatalogPaper(id: 'frm2_5', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Risk Management and Investment Management'),
            CatalogPaper(id: 'frm2_6', programId: 'frm_part2', levelId: 'frm_p2_lvl', title: 'Current Issues in Financial Markets'),
          ]
        )
      ]
    ),
  ];

  // ─── ACTUARIAL ───────────────────────────────────────────────────────

  static const _actuarialFamily = CatalogFamily(
    id: 'actuarial',
    categoryId: categoryId,
    title: 'Actuarial Sciences',
    shortTitle: 'Actuarial',
    programIds: ['actuarial_ifoa_iai', 'actuarial_soa'],
  );

  static List<CatalogProgram> _getActuarialPrograms() => [
    CatalogProgram(
      id: 'actuarial_ifoa_iai',
      familyId: 'actuarial',
      categoryId: categoryId,
      title: 'Actuarial (IFoA / IAI)',
      authority: 'Institute of Actuaries',
      levels: [
        CatalogLevel(
          id: 'act_ifoa_lvl',
          programId: 'actuarial_ifoa_iai',
          title: 'IFoA / IAI Structure',
          children: [
            CatalogLevel(
              id: 'act_ifoa_core_prin',
              programId: 'actuarial_ifoa_iai',
              title: 'Core Principles',
              type: CatalogNodeType.module,
              papers: [
                CatalogPaper(id: 'act_cs1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CS1 Actuarial Statistics'),
                CatalogPaper(id: 'act_cs2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CS2 Risk Modelling and Survival Analysis'),
                CatalogPaper(id: 'act_cm1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CM1 Actuarial Mathematics for Modelling'),
                CatalogPaper(id: 'act_cm2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CM2 Economic Modelling'),
                CatalogPaper(id: 'act_cb1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CB1 Business Finance'),
                CatalogPaper(id: 'act_cb2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CB2 Business Economics'),
                CatalogPaper(id: 'act_cb3', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prin', title: 'CB3 Business Management'),
              ]
            ),
            CatalogLevel(
              id: 'act_ifoa_core_prac',
              programId: 'actuarial_ifoa_iai',
              title: 'Core Practices',
              type: CatalogNodeType.module,
              papers: [
                CatalogPaper(id: 'act_cp1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prac', title: 'CP1 Actuarial Practice'),
                CatalogPaper(id: 'act_cp2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prac', title: 'CP2 Modelling Practice'),
                CatalogPaper(id: 'act_cp3', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_core_prac', title: 'CP3 Communications Practice'),
              ]
            ),
            CatalogLevel(
              id: 'act_ifoa_sp',
              programId: 'actuarial_ifoa_iai',
              title: 'Specialist Principles (Select 2)',
              type: CatalogNodeType.module,
              papers: [
                CatalogPaper(id: 'act_sp1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP1 Health and Care', isOptional: true),
                CatalogPaper(id: 'act_sp2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP2 Life Insurance', isOptional: true),
                CatalogPaper(id: 'act_sp4', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP4 Pensions and Other Benefits', isOptional: true),
                CatalogPaper(id: 'act_sp5', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP5 Investment and Finance', isOptional: true),
                CatalogPaper(id: 'act_sp6', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP6 Financial Derivatives', isOptional: true),
                CatalogPaper(id: 'act_sp7', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP7 General Insurance Reserving and Capital Modelling', isOptional: true),
                CatalogPaper(id: 'act_sp8', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP8 General Insurance Pricing', isOptional: true),
                CatalogPaper(id: 'act_sp9', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sp', title: 'SP9 Enterprise Risk Management', isOptional: true),
              ]
            ),
            CatalogLevel(
              id: 'act_ifoa_sa',
              programId: 'actuarial_ifoa_iai',
              title: 'Specialist Advanced (Select 1)',
              type: CatalogNodeType.module,
              papers: [
                CatalogPaper(id: 'act_sa1', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sa', title: 'SA1 Health and Care', isOptional: true),
                CatalogPaper(id: 'act_sa2', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sa', title: 'SA2 Life Insurance', isOptional: true),
                CatalogPaper(id: 'act_sa3', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sa', title: 'SA3 General Insurance', isOptional: true),
                CatalogPaper(id: 'act_sa4', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sa', title: 'SA4 Pensions and Other Benefits', isOptional: true),
                CatalogPaper(id: 'act_sa7', programId: 'actuarial_ifoa_iai', levelId: 'act_ifoa_sa', title: 'SA7 Investment and Finance', isOptional: true),
              ]
            )
          ]
        )
      ]
    ),
    CatalogProgram(
      id: 'actuarial_soa',
      familyId: 'actuarial',
      categoryId: categoryId,
      title: 'Actuarial (SOA)',
      authority: 'Society of Actuaries',
      levels: [
        CatalogLevel(
          id: 'act_soa_lvl',
          programId: 'actuarial_soa',
          title: 'SOA Foundation',
          papers: [
            CatalogPaper(id: 'soa_p', programId: 'actuarial_soa', levelId: 'act_soa_lvl', title: 'Probability (P)'),
            CatalogPaper(id: 'soa_fm', programId: 'actuarial_soa', levelId: 'act_soa_lvl', title: 'Financial Mathematics (FM)'),
            CatalogPaper(id: 'soa_ifm', programId: 'actuarial_soa', levelId: 'act_soa_lvl', title: 'Investment and Financial Markets (IFM)'),
          ]
        )
      ]
    ),
  ];
}
