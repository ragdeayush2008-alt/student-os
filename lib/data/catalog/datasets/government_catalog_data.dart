import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_node.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';

abstract final class GovernmentCatalogData {
  static const categoryId = 'government_job_exams';

  static List<CatalogFamily> getFamilies() => [
    _upscFamily,
    _sscFamily,
    _bankingFamily,
    _defenceFamily,
    _teachingFamily,
    _statePscFamily,
    _researchNetFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getUPSCPrograms(),
    ..._getSSCPrograms(),
    ..._getBankingPrograms(),
    ..._getDefencePrograms(),
    ..._getTeachingPrograms(),
    ..._getStatePSCPrograms(),
    ..._getResearchNETPrograms(),
  ];

  // ─── UPSC ────────────────────────────────────────────────────────────

  static const _upscFamily = CatalogFamily(
    id: 'upsc',
    categoryId: categoryId,
    title: 'Union Public Service Commission',
    shortTitle: 'UPSC',
    description: 'Civil Services (IAS/IPS/IFS), Engineering Services, CDS, NDA',
    aliases: ['IAS', 'IPS', 'UPSC CSE', 'Civil Services'],
    isPopular: true,
    programIds: ['upsc_cse', 'upsc_ese', 'upsc_capf'],
  );

  static List<CatalogProgram> _getUPSCPrograms() => [
    CatalogProgram(
      id: 'upsc_cse',
      familyId: 'upsc',
      categoryId: categoryId,
      title: 'UPSC Civil Services (IAS / IPS / IFS)',
      authority: 'UPSC',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'upsc_cse_prelims',
          programId: 'upsc_cse',
          title: 'Preliminary Examination',
          type: CatalogNodeType.stage,
          papers: [
            CatalogPaper(id: 'upsc_p_gs1', programId: 'upsc_cse', levelId: 'upsc_cse_prelims', title: 'General Studies I (History, Geography, Polity, Economy, Environment, Science & Tech, Current Affairs)', order: 1),
            CatalogPaper(id: 'upsc_p_csat', programId: 'upsc_cse', levelId: 'upsc_cse_prelims', title: 'General Studies II (CSAT - Comprehension, Logical Reasoning, Quantitative Aptitude)', order: 2),
          ],
        ),
        CatalogLevel(
          id: 'upsc_cse_mains',
          programId: 'upsc_cse',
          title: 'Main Examination',
          type: CatalogNodeType.stage,
          papers: [
            CatalogPaper(id: 'upsc_m_essay', programId: 'upsc_cse', levelId: 'upsc_cse_mains', title: 'Essay Paper', order: 1),
            CatalogPaper(id: 'upsc_m_gs1', programId: 'upsc_cse', levelId: 'upsc_cse_mains', title: 'General Studies I (Indian Heritage, History & Geography, Society)', order: 2),
            CatalogPaper(id: 'upsc_m_gs2', programId: 'upsc_cse', levelId: 'upsc_cse_mains', title: 'General Studies II (Governance, Constitution, Polity, Social Justice, IR)', order: 3),
            CatalogPaper(id: 'upsc_m_gs3', programId: 'upsc_cse', levelId: 'upsc_cse_mains', title: 'General Studies III (Technology, Economic Development, Biodiversity, Security, Disaster Management)', order: 4),
            CatalogPaper(id: 'upsc_m_gs4', programId: 'upsc_cse', levelId: 'upsc_cse_mains', title: 'General Studies IV (Ethics, Integrity and Aptitude)', order: 5),
          ],
        ),
      ],
    ),
  ];

  // ─── SSC ─────────────────────────────────────────────────────────────

  static const _sscFamily = CatalogFamily(
    id: 'ssc',
    categoryId: categoryId,
    title: 'Staff Selection Commission',
    shortTitle: 'SSC',
    description: 'SSC CGL, CHSL, MTS, CPO & JE Recruitment',
    aliases: ['SSC CGL', 'SSC CHSL', 'SSC MTS', 'Staff Selection'],
    isPopular: true,
    programIds: ['ssc_cgl', 'ssc_chsl', 'ssc_mts', 'ssc_cpo', 'ssc_je'],
  );

  static List<CatalogProgram> _getSSCPrograms() => [
    CatalogProgram(
      id: 'ssc_cgl',
      familyId: 'ssc',
      categoryId: categoryId,
      title: 'SSC CGL (Combined Graduate Level)',
      authority: 'Staff Selection Commission',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'ssc_cgl_tier1',
          programId: 'ssc_cgl',
          title: 'Tier I (Computer Based Test)',
          type: CatalogNodeType.stage,
          papers: [
            CatalogPaper(id: 'ssc_t1_gi_lr', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier1', title: 'General Intelligence and Reasoning', order: 1),
            CatalogPaper(id: 'ssc_t1_ga', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier1', title: 'General Awareness', order: 2),
            CatalogPaper(id: 'ssc_t1_qa', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier1', title: 'Quantitative Aptitude', order: 3),
            CatalogPaper(id: 'ssc_t1_eng', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier1', title: 'English Comprehension', order: 4),
          ],
        ),
        CatalogLevel(
          id: 'ssc_cgl_tier2',
          programId: 'ssc_cgl',
          title: 'Tier II (Mains)',
          type: CatalogNodeType.stage,
          papers: [
            CatalogPaper(id: 'ssc_t2_math', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier2', title: 'Mathematical Abilities', order: 1),
            CatalogPaper(id: 'ssc_t2_reasoning', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier2', title: 'Reasoning and General Intelligence', order: 2),
            CatalogPaper(id: 'ssc_t2_english', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier2', title: 'English Language and Comprehension', order: 3),
            CatalogPaper(id: 'ssc_t2_ga', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier2', title: 'General Awareness', order: 4),
            CatalogPaper(id: 'ssc_t2_comp', programId: 'ssc_cgl', levelId: 'ssc_cgl_tier2', title: 'Computer Knowledge Module', order: 5),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'ssc_chsl',
      familyId: 'ssc',
      categoryId: categoryId,
      title: 'SSC CHSL (10+2 Level)',
      authority: 'Staff Selection Commission',
      levels: [
        CatalogLevel(
          id: 'ssc_chsl_tier1',
          programId: 'ssc_chsl',
          title: 'Tier I CBT',
          papers: [
            CatalogPaper(id: 'ssc_chsl_eng', programId: 'ssc_chsl', levelId: 'ssc_chsl_tier1', title: 'English Language'),
            CatalogPaper(id: 'ssc_chsl_gi', programId: 'ssc_chsl', levelId: 'ssc_chsl_tier1', title: 'General Intelligence'),
            CatalogPaper(id: 'ssc_chsl_qa', programId: 'ssc_chsl', levelId: 'ssc_chsl_tier1', title: 'Quantitative Aptitude'),
            CatalogPaper(id: 'ssc_chsl_ga', programId: 'ssc_chsl', levelId: 'ssc_chsl_tier1', title: 'General Awareness'),
          ],
        ),
      ],
    ),
  ];

  // ─── BANKING ─────────────────────────────────────────────────────────

  static const _bankingFamily = CatalogFamily(
    id: 'banking',
    categoryId: 'banking_financial_recruitment',
    title: 'Banking & Regulatory Bodies',
    shortTitle: 'Banking (IBPS/SBI/RBI)',
    description: 'IBPS PO/Clerk, SBI PO/Clerk, RBI Grade B, SEBI & NABARD',
    aliases: ['Bank PO', 'SBI PO', 'IBPS PO', 'RBI Grade B'],
    isPopular: true,
    programIds: ['ibps_po', 'sbi_po', 'rbi_grade_b', 'sebi_grade_a'],
  );

  static List<CatalogProgram> _getBankingPrograms() => [
    CatalogProgram(
      id: 'ibps_po',
      familyId: 'banking',
      categoryId: 'banking_financial_recruitment',
      title: 'IBPS PO (Probationary Officer)',
      authority: 'IBPS',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'ibps_po_prelims',
          programId: 'ibps_po',
          title: 'Prelims',
          papers: [
            CatalogPaper(id: 'ibps_p_eng', programId: 'ibps_po', levelId: 'ibps_po_prelims', title: 'English Language', order: 1),
            CatalogPaper(id: 'ibps_p_qa', programId: 'ibps_po', levelId: 'ibps_po_prelims', title: 'Quantitative Aptitude', order: 2),
            CatalogPaper(id: 'ibps_p_lr', programId: 'ibps_po', levelId: 'ibps_po_prelims', title: 'Reasoning Ability', order: 3),
          ],
        ),
        CatalogLevel(
          id: 'ibps_po_mains',
          programId: 'ibps_po',
          title: 'Mains',
          papers: [
            CatalogPaper(id: 'ibps_m_reasoning_ca', programId: 'ibps_po', levelId: 'ibps_po_mains', title: 'Reasoning & Computer Aptitude', order: 1),
            CatalogPaper(id: 'ibps_m_ga_banking', programId: 'ibps_po', levelId: 'ibps_po_mains', title: 'General / Economy / Banking Awareness', order: 2),
            CatalogPaper(id: 'ibps_m_english', programId: 'ibps_po', levelId: 'ibps_po_mains', title: 'English Language', order: 3),
            CatalogPaper(id: 'ibps_m_di', programId: 'ibps_po', levelId: 'ibps_po_mains', title: 'Data Analysis & Interpretation', order: 4),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'sbi_po',
      familyId: 'banking',
      categoryId: 'banking_financial_recruitment',
      title: 'SBI PO (State Bank of India)',
      authority: 'SBI',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'sbi_po_pre',
          programId: 'sbi_po',
          title: 'Preliminary Exam',
          papers: [
            CatalogPaper(id: 'sbi_p_eng', programId: 'sbi_po', levelId: 'sbi_po_pre', title: 'English Language'),
            CatalogPaper(id: 'sbi_p_qa', programId: 'sbi_po', levelId: 'sbi_po_pre', title: 'Quantitative Aptitude'),
            CatalogPaper(id: 'sbi_p_lr', programId: 'sbi_po', levelId: 'sbi_po_pre', title: 'Reasoning Ability'),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'rbi_grade_b',
      familyId: 'banking',
      categoryId: 'banking_financial_recruitment',
      title: 'RBI Grade B Officer',
      authority: 'Reserve Bank of India',
      levels: [
        CatalogLevel(
          id: 'rbi_b_phase1',
          programId: 'rbi_grade_b',
          title: 'Phase I (Online Examination)',
          papers: [
            CatalogPaper(id: 'rbi_p1_ga', programId: 'rbi_grade_b', levelId: 'rbi_b_phase1', title: 'General Awareness'),
            CatalogPaper(id: 'rbi_p1_eng', programId: 'rbi_grade_b', levelId: 'rbi_b_phase1', title: 'English Language'),
            CatalogPaper(id: 'rbi_p1_qa', programId: 'rbi_grade_b', levelId: 'rbi_b_phase1', title: 'Quantitative Aptitude'),
            CatalogPaper(id: 'rbi_p1_lr', programId: 'rbi_grade_b', levelId: 'rbi_b_phase1', title: 'Reasoning'),
          ],
        ),
        CatalogLevel(
          id: 'rbi_b_phase2',
          programId: 'rbi_grade_b',
          title: 'Phase II (Mains)',
          papers: [
            CatalogPaper(id: 'rbi_p2_esi', programId: 'rbi_grade_b', levelId: 'rbi_b_phase2', title: 'Economic and Social Issues (ESI)'),
            CatalogPaper(id: 'rbi_p2_eng', programId: 'rbi_grade_b', levelId: 'rbi_b_phase2', title: 'English (Writing Skills)'),
            CatalogPaper(id: 'rbi_p2_fm', programId: 'rbi_grade_b', levelId: 'rbi_b_phase2', title: 'Finance and Management (FM)'),
          ],
        ),
      ],
    ),
  ];

  // ─── DEFENCE ─────────────────────────────────────────────────────────

  static const _defenceFamily = CatalogFamily(
    id: 'defence',
    categoryId: 'defence',
    title: 'Defence & Armed Forces Recruitment',
    shortTitle: 'Defence',
    programIds: ['nda_exam', 'cds_exam', 'afcat_exam'],
  );

  static List<CatalogProgram> _getDefencePrograms() => [
    CatalogProgram(
      id: 'nda_exam',
      familyId: 'defence',
      categoryId: 'defence',
      title: 'NDA (National Defence Academy)',
      authority: 'UPSC',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'nda_lvl',
          programId: 'nda_exam',
          title: 'NDA Written Exam',
          papers: [
            CatalogPaper(id: 'nda_math', programId: 'nda_exam', levelId: 'nda_lvl', title: 'Mathematics', order: 1),
            CatalogPaper(id: 'nda_gat', programId: 'nda_exam', levelId: 'nda_lvl', title: 'General Ability Test (English & General Knowledge)', order: 2),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'cds_exam',
      familyId: 'defence',
      categoryId: 'defence',
      title: 'CDS (Combined Defence Services)',
      authority: 'UPSC',
      levels: [
        CatalogLevel(
          id: 'cds_lvl',
          programId: 'cds_exam',
          title: 'CDS Written Exam',
          papers: [
            CatalogPaper(id: 'cds_eng', programId: 'cds_exam', levelId: 'cds_lvl', title: 'English'),
            CatalogPaper(id: 'cds_gk', programId: 'cds_exam', levelId: 'cds_lvl', title: 'General Knowledge'),
            CatalogPaper(id: 'cds_math', programId: 'cds_exam', levelId: 'cds_lvl', title: 'Elementary Mathematics'),
          ],
        ),
      ],
    ),
  ];

  // ─── TEACHING ────────────────────────────────────────────────────────

  static const _teachingFamily = CatalogFamily(
    id: 'teaching',
    categoryId: 'teaching_education',
    title: 'Teacher Eligibility & Recruitment',
    shortTitle: 'Teaching (TET/CTET)',
    programIds: ['ctet_exam'],
  );

  static List<CatalogProgram> _getTeachingPrograms() => [
    CatalogProgram(
      id: 'ctet_exam',
      familyId: 'teaching',
      categoryId: 'teaching_education',
      title: 'CTET (Central Teacher Eligibility Test)',
      authority: 'CBSE',
      levels: [
        CatalogLevel(
          id: 'ctet_p1',
          programId: 'ctet_exam',
          title: 'Paper I (Classes 1 to 5)',
          papers: [
            CatalogPaper(id: 'ctet_cdp', programId: 'ctet_exam', levelId: 'ctet_p1', title: 'Child Development and Pedagogy'),
            CatalogPaper(id: 'ctet_l1', programId: 'ctet_exam', levelId: 'ctet_p1', title: 'Language I'),
            CatalogPaper(id: 'ctet_l2', programId: 'ctet_exam', levelId: 'ctet_p1', title: 'Language II'),
            CatalogPaper(id: 'ctet_math', programId: 'ctet_exam', levelId: 'ctet_p1', title: 'Mathematics'),
            CatalogPaper(id: 'ctet_evs', programId: 'ctet_exam', levelId: 'ctet_p1', title: 'Environmental Studies (EVS)'),
          ],
        ),
      ],
    ),
  ];

  // ─── STATE PSC ───────────────────────────────────────────────────────

  static const _statePscFamily = CatalogFamily(
    id: 'state_psc',
    categoryId: categoryId,
    title: 'State Public Service Commissions',
    shortTitle: 'State PSC',
    programIds: ['mpsc_rajyaseva'],
  );

  static List<CatalogProgram> _getStatePSCPrograms() => [
    CatalogProgram(
      id: 'mpsc_rajyaseva',
      familyId: 'state_psc',
      categoryId: categoryId,
      title: 'MPSC State Services (Rajyaseva)',
      authority: 'Maharashtra Public Service Commission',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'mpsc_prelims',
          programId: 'mpsc_rajyaseva',
          title: 'MPSC Prelims (Descriptive / Pattern)',
          papers: [
            CatalogPaper(id: 'mpsc_gs1', programId: 'mpsc_rajyaseva', levelId: 'mpsc_prelims', title: 'General Studies Paper 1'),
            CatalogPaper(id: 'mpsc_csat', programId: 'mpsc_rajyaseva', levelId: 'mpsc_prelims', title: 'CSAT (General Studies Paper 2)'),
          ],
        ),
      ],
    ),
  ];

  // ─── RESEARCH / UGC NET ──────────────────────────────────────────────

  static const _researchNetFamily = CatalogFamily(
    id: 'research_net',
    categoryId: 'research_net_exams',
    title: 'UGC NET & CSIR NET',
    shortTitle: 'UGC NET / Research',
    description: 'National Eligibility Test for JRF and Assistant Professorship across 80+ subjects',
    programIds: ['ugc_net_exam', 'csir_net_exam'],
  );

  static List<CatalogProgram> _getResearchNETPrograms() {
    final ugcNetSubjects = [
      ('01', 'Economics / Econometrics', 'Economics'),
      ('02', 'Political Science', 'Political Science'),
      ('03', 'Philosophy', 'Philosophy'),
      ('04', 'Psychology', 'Psychology'),
      ('05', 'Sociology', 'Sociology'),
      ('06', 'History', 'History'),
      ('08', 'Commerce', 'Commerce'),
      ('09', 'Education', 'Education'),
      ('17', 'Management', 'Management'),
      ('30', 'English', 'English'),
      ('58', 'Law', 'Law'),
      ('87', 'Computer Science and Applications', 'Computer Science'),
      ('88', 'Electronic Science', 'Electronic Science'),
      ('89', 'Environmental Sciences', 'Environmental Sciences'),
    ];

    return [
      CatalogProgram(
        id: 'ugc_net_exam',
        familyId: 'research_net',
        categoryId: 'research_net_exams',
        title: 'UGC NET',
        authority: 'NTA / UGC',
        defaultYear: '2026',
        levels: ugcNetSubjects.map((s) {
          final (code, name, disc) = s;
          return CatalogLevel(
            id: 'ugc_net_$code',
            programId: 'ugc_net_exam',
            title: '$name (Subject $code)',
            code: code,
            description: 'Paper 1 (Teaching & Research Aptitude) + Paper 2 ($disc)',
            papers: [
              CatalogPaper(id: 'ugc_net_p1', programId: 'ugc_net_exam', levelId: 'ugc_net_$code', title: 'Paper 1: Teaching & Research Aptitude', order: 1),
              CatalogPaper(id: 'ugc_net_${code}_p2', programId: 'ugc_net_exam', levelId: 'ugc_net_$code', title: 'Paper 2: $name', order: 2),
            ],
          );
        }).toList(),
      ),
      CatalogProgram(
        id: 'csir_net_exam',
        familyId: 'research_net',
        categoryId: 'research_net_exams',
        title: 'CSIR UGC NET (Sciences)',
        authority: 'NTA / CSIR',
        levels: [
          CatalogLevel(
            id: 'csir_chem',
            programId: 'csir_net_exam',
            title: 'Chemical Sciences',
            papers: [
              CatalogPaper(id: 'csir_ga', programId: 'csir_net_exam', levelId: 'csir_chem', title: 'Part A: General Aptitude'),
              CatalogPaper(id: 'csir_chem_core', programId: 'csir_net_exam', levelId: 'csir_chem', title: 'Parts B & C: Chemical Sciences'),
            ],
          ),
          CatalogLevel(
            id: 'csir_life',
            programId: 'csir_net_exam',
            title: 'Life Sciences',
            papers: [
              CatalogPaper(id: 'csir_ga_life', programId: 'csir_net_exam', levelId: 'csir_life', title: 'Part A: General Aptitude'),
              CatalogPaper(id: 'csir_life_core', programId: 'csir_net_exam', levelId: 'csir_life', title: 'Parts B & C: Life Sciences'),
            ],
          ),
          CatalogLevel(
            id: 'csir_math',
            programId: 'csir_net_exam',
            title: 'Mathematical Sciences',
            papers: [
              CatalogPaper(id: 'csir_ga_math', programId: 'csir_net_exam', levelId: 'csir_math', title: 'Part A: General Aptitude'),
              CatalogPaper(id: 'csir_math_core', programId: 'csir_net_exam', levelId: 'csir_math', title: 'Parts B & C: Mathematical Sciences'),
            ],
          ),
          CatalogLevel(
            id: 'csir_phy',
            programId: 'csir_net_exam',
            title: 'Physical Sciences',
            papers: [
              CatalogPaper(id: 'csir_ga_phy', programId: 'csir_net_exam', levelId: 'csir_phy', title: 'Part A: General Aptitude'),
              CatalogPaper(id: 'csir_phy_core', programId: 'csir_net_exam', levelId: 'csir_phy', title: 'Parts B & C: Physical Sciences'),
            ],
          ),
        ],
      ),
    ];
  }
}
