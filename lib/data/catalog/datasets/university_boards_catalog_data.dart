import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_node.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';
import '../../models/catalog/catalog_subject.dart';

abstract final class UniversityBoardsCatalogData {
  static List<CatalogFamily> getFamilies() => [
    _cuetUgFamily,
    _cuetPgFamily,
    _designFamily,
    _architectureFamily,
    _agricultureFamily,
    _schoolCbseFamily,
    _schoolIcseFamily,
    _schoolMhBoardFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getCUETUGPrograms(),
    ..._getCUETPGPrograms(),
    ..._getDesignPrograms(),
    ..._getArchitecturePrograms(),
    ..._getAgriculturePrograms(),
    ..._getSchoolCBSEPrograms(),
    ..._getSchoolICSEPrograms(),
    ..._getSchoolMhBoardPrograms(),
  ];

  // ─── CUET UG ─────────────────────────────────────────────────────────

  static const _cuetUgFamily = CatalogFamily(
    id: 'cuet_ug',
    categoryId: 'science_university_entrance',
    title: 'Common University Entrance Test (UG)',
    shortTitle: 'CUET UG',
    description: 'Central and State Universities Undergraduate Entrance',
    aliases: ['CUET 2026', 'CUET UG', 'NTA CUET', 'Central Universities'],
    isPopular: true,
    programIds: ['cuet_ug_exam'],
  );

  static List<CatalogProgram> _getCUETUGPrograms() {
    final languages = [
      ('cuet_lang_eng', 'English', '101'),
      ('cuet_lang_hin', 'Hindi', '102'),
      ('cuet_lang_asm', 'Assamese', '103'),
      ('cuet_lang_ben', 'Bengali', '104'),
      ('cuet_lang_guj', 'Gujarati', '105'),
      ('cuet_lang_kan', 'Kannada', '106'),
      ('cuet_lang_mal', 'Malayalam', '107'),
      ('cuet_lang_mar', 'Marathi', '108'),
      ('cuet_lang_odi', 'Odia', '109'),
      ('cuet_lang_pun', 'Punjabi', '110'),
      ('cuet_lang_tam', 'Tamil', '111'),
      ('cuet_lang_tel', 'Telugu', '112'),
      ('cuet_lang_urd', 'Urdu', '113'),
    ];

    final domains = [
      ('cuet_dom_acc', 'Accountancy / Book Keeping', '301'),
      ('cuet_dom_agri', 'Agriculture', '302'),
      ('cuet_dom_anthro', 'Anthropology', '303'),
      ('cuet_dom_bio', 'Biology / Biological Studies / Biotechnology / Biochemistry', '304'),
      ('cuet_dom_bst', 'Business Studies', '305'),
      ('cuet_dom_chem', 'Chemistry', '306'),
      ('cuet_dom_evs', 'Environmental Studies', '307'),
      ('cuet_dom_cs', 'Computer Science / Informatics Practices', '308'),
      ('cuet_dom_eco', 'Economics / Business Economics', '309'),
      ('cuet_dom_fine_art', 'Fine Arts / Visual Arts / Commercial Art', '310'),
      ('cuet_dom_geo', 'Geography / Geology', '311'),
      ('cuet_dom_hist', 'History', '312'),
      ('cuet_dom_home_sci', 'Home Science', '313'),
      ('cuet_dom_ktpi', 'Knowledge Tradition & Practices in India', '314'),
      ('cuet_dom_mass_media', 'Mass Media / Mass Communication', '315'),
      ('cuet_dom_math', 'Mathematics / Applied Mathematics', '316'),
      ('cuet_dom_perf_arts', 'Performing Arts', '317'),
      ('cuet_dom_pe', 'Physical Education / NCC / Yoga', '318'),
      ('cuet_dom_phy', 'Physics', '319'),
      ('cuet_dom_pol_sci', 'Political Science', '320'),
      ('cuet_dom_psych', 'Psychology', '321'),
      ('cuet_dom_sans', 'Sanskrit', '322'),
      ('cuet_dom_socio', 'Sociology', '323'),
    ];

    return [
      CatalogProgram(
        id: 'cuet_ug_exam',
        familyId: 'cuet_ug',
        categoryId: 'science_university_entrance',
        title: 'CUET UG',
        authority: 'NTA',
        defaultYear: '2026',
        isPopular: true,
        levels: [
          CatalogLevel(
            id: 'cuet_ug_structure',
            programId: 'cuet_ug_exam',
            title: 'CUET UG 2026 Structure',
            children: [
              CatalogLevel(
                id: 'cuet_section_1a',
                programId: 'cuet_ug_exam',
                title: 'Section IA & IB: Languages',
                type: CatalogNodeType.group,
                papers: languages.map((l) {
                  final (id, name, code) = l;
                  return CatalogPaper(
                    id: id,
                    programId: 'cuet_ug_exam',
                    levelId: 'cuet_section_1a',
                    title: name,
                    code: code,
                    type: SubjectRequirementType.elective,
                    isOptional: true,
                  );
                }).toList(),
              ),
              CatalogLevel(
                id: 'cuet_section_2',
                programId: 'cuet_ug_exam',
                title: 'Section II: Domain Specific Subjects',
                type: CatalogNodeType.group,
                papers: domains.map((d) {
                  final (id, name, code) = d;
                  return CatalogPaper(
                    id: id,
                    programId: 'cuet_ug_exam',
                    levelId: 'cuet_section_2',
                    title: name,
                    code: code,
                    type: SubjectRequirementType.elective,
                    isOptional: true,
                  );
                }).toList(),
              ),
              CatalogLevel(
                id: 'cuet_section_3',
                programId: 'cuet_ug_exam',
                title: 'Section III: General Test',
                type: CatalogNodeType.group,
                papers: [
                  CatalogPaper(
                    id: 'cuet_gat',
                    programId: 'cuet_ug_exam',
                    levelId: 'cuet_section_3',
                    title: 'General Aptitude Test (GK, Current Affairs, General Mental Ability, Numerical Ability, Reasoning)',
                    code: '501',
                    type: SubjectRequirementType.elective,
                    isOptional: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  // ─── CUET PG ─────────────────────────────────────────────────────────

  static const _cuetPgFamily = CatalogFamily(
    id: 'cuet_pg',
    categoryId: 'postgraduate_entrance',
    title: 'Common University Entrance Test (PG)',
    shortTitle: 'CUET PG',
    programIds: ['cuet_pg_exam'],
  );

  static List<CatalogProgram> _getCUETPGPrograms() => [
    CatalogProgram(
      id: 'cuet_pg_exam',
      familyId: 'cuet_pg',
      categoryId: 'postgraduate_entrance',
      title: 'CUET PG',
      authority: 'NTA',
      levels: [
        CatalogLevel(
          id: 'cuet_pg_gen',
          programId: 'cuet_pg_exam',
          title: 'General / MBA Papers (COQP11 / COQP12)',
          papers: [
            CatalogPaper(id: 'cuet_pg_qa', programId: 'cuet_pg_exam', levelId: 'cuet_pg_gen', title: 'Quantitative Ability'),
            CatalogPaper(id: 'cuet_pg_lr', programId: 'cuet_pg_exam', levelId: 'cuet_pg_gen', title: 'Logical Reasoning'),
            CatalogPaper(id: 'cuet_pg_va', programId: 'cuet_pg_exam', levelId: 'cuet_pg_gen', title: 'Verbal Ability & English Comprehension'),
            CatalogPaper(id: 'cuet_pg_gk', programId: 'cuet_pg_exam', levelId: 'cuet_pg_gen', title: 'General Knowledge'),
          ],
        ),
      ],
    ),
  ];

  // ─── DESIGN & CREATIVE ARTS ──────────────────────────────────────────

  static const _designFamily = CatalogFamily(
    id: 'design',
    categoryId: 'design',
    title: 'Design Entrances (UCEED, NID, NIFT)',
    shortTitle: 'Design Entrances',
    programIds: ['uceed_exam', 'nid_dat_exam', 'nift_exam'],
  );

  static List<CatalogProgram> _getDesignPrograms() => [
    CatalogProgram(
      id: 'uceed_exam',
      familyId: 'design',
      categoryId: 'design',
      title: 'UCEED (IIT Bombay)',
      authority: 'IIT Bombay',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'uceed_lvl',
          programId: 'uceed_exam',
          title: 'Part A & Part B',
          papers: [
            CatalogPaper(id: 'uceed_part_a', programId: 'uceed_exam', levelId: 'uceed_lvl', title: 'Part A (Visualization & Spatial Ability, Observation & Design Sensitivity, Analytical Reasoning, Environmental & Social Awareness, Language & Creativity)'),
            CatalogPaper(id: 'uceed_part_b', programId: 'uceed_exam', levelId: 'uceed_lvl', title: 'Part B (Drawing & Design Aptitude)'),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'nid_dat_exam',
      familyId: 'design',
      categoryId: 'design',
      title: 'NID DAT (Design Aptitude Test)',
      authority: 'NID Ahmedabad',
      levels: [
        CatalogLevel(
          id: 'nid_lvl',
          programId: 'nid_dat_exam',
          title: 'DAT Prelims & Mains',
          papers: [
            CatalogPaper(id: 'nid_prelims', programId: 'nid_dat_exam', levelId: 'nid_lvl', title: 'DAT Prelims (Objective & Visual/Creative Skills)'),
            CatalogPaper(id: 'nid_mains', programId: 'nid_dat_exam', levelId: 'nid_lvl', title: 'DAT Mains (Studio Test & Portfolio)'),
          ],
        ),
      ],
    ),
  ];

  // ─── ARCHITECTURE ────────────────────────────────────────────────────

  static const _architectureFamily = CatalogFamily(
    id: 'architecture',
    categoryId: 'architecture_planning',
    title: 'Architecture Entrances (NATA / JEE Paper 2)',
    shortTitle: 'Architecture Entrances',
    programIds: ['nata_exam', 'jee_paper_2'],
  );

  static List<CatalogProgram> _getArchitecturePrograms() => [
    CatalogProgram(
      id: 'nata_exam',
      familyId: 'architecture',
      categoryId: 'architecture_planning',
      title: 'NATA (National Aptitude Test in Architecture)',
      authority: 'Council of Architecture (CoA)',
      levels: [
        CatalogLevel(
          id: 'nata_lvl',
          programId: 'nata_exam',
          title: 'NATA Test Sections',
          papers: [
            CatalogPaper(id: 'nata_drawing', programId: 'nata_exam', levelId: 'nata_lvl', title: 'Drawing & Composition Test'),
            CatalogPaper(id: 'nata_aptitude', programId: 'nata_exam', levelId: 'nata_lvl', title: 'Aesthetic Sensitivity & Architectural Aptitude'),
            CatalogPaper(id: 'nata_math', programId: 'nata_exam', levelId: 'nata_lvl', title: 'Mathematics'),
          ],
        ),
      ],
    ),
  ];

  // ─── AGRICULTURE ─────────────────────────────────────────────────────

  static const _agricultureFamily = CatalogFamily(
    id: 'agriculture',
    categoryId: 'agriculture',
    title: 'ICAR & State Agriculture Entrances',
    shortTitle: 'Agriculture',
    programIds: ['icar_aieea_ug'],
  );

  static List<CatalogProgram> _getAgriculturePrograms() => [
    CatalogProgram(
      id: 'icar_aieea_ug',
      familyId: 'agriculture',
      categoryId: 'agriculture',
      title: 'ICAR AIEEA (UG Agriculture)',
      authority: 'NTA / ICAR',
      levels: [
        CatalogLevel(
          id: 'icar_lvl',
          programId: 'icar_aieea_ug',
          title: 'Agriculture Entrance Stream',
          papers: [
            CatalogPaper(id: 'icar_phy', programId: 'icar_aieea_ug', levelId: 'icar_lvl', title: 'Physics'),
            CatalogPaper(id: 'icar_chem', programId: 'icar_aieea_ug', levelId: 'icar_lvl', title: 'Chemistry'),
            CatalogPaper(id: 'icar_agri_bio', programId: 'icar_aieea_ug', levelId: 'icar_lvl', title: 'Agriculture / Biology / Mathematics'),
          ],
        ),
      ],
    ),
  ];

  // ─── SCHOOL & BOARDS ─────────────────────────────────────────────────

  static const _schoolCbseFamily = CatalogFamily(
    id: 'cbse',
    categoryId: 'school_boards_olympiads',
    title: 'CBSE (Central Board of Secondary Education)',
    shortTitle: 'CBSE Board',
    aliases: ['CBSE', 'NCERT', 'Class 10', 'Class 12', 'Class 9', 'Class 11'],
    isPopular: true,
    programIds: ['cbse_class_10', 'cbse_class_12', 'cbse_class_11', 'cbse_class_9', 'cbse_primary', 'cbse_middle'],
  );

  static List<CatalogProgram> _getSchoolCBSEPrograms() => [
    CatalogProgram(
      id: 'cbse_class_10',
      familyId: 'cbse',
      categoryId: 'school_boards_olympiads',
      title: 'Class 10 CBSE',
      authority: 'CBSE',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'node_cbse_class_10',
          programId: 'cbse_class_10',
          title: 'Class 10 CBSE Board',
          papers: [
            CatalogPaper(id: 'cbse_c10_eng_lang_lit', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'English Language and Literature', code: '184', order: 1),
            CatalogPaper(id: 'cbse_c10_math_std', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Mathematics (Standard)', code: '041', order: 2),
            CatalogPaper(id: 'cbse_c10_math_basic', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Mathematics (Basic)', code: '241', type: SubjectRequirementType.elective, isOptional: true, order: 3),
            CatalogPaper(id: 'cbse_c10_science', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Science', code: '086', order: 4),
            CatalogPaper(id: 'cbse_c10_social_science', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Social Science', code: '087', order: 5),
            CatalogPaper(id: 'cbse_c10_it', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Information Technology', code: '402', type: SubjectRequirementType.elective, isOptional: true, order: 6),
            CatalogPaper(id: 'cbse_c10_ai', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Artificial Intelligence', code: '417', type: SubjectRequirementType.elective, isOptional: true, order: 7),
            CatalogPaper(id: 'cbse_c10_hindi_a', programId: 'cbse_class_10', levelId: 'node_cbse_class_10', title: 'Hindi Course-A', code: '002', type: SubjectRequirementType.elective, isOptional: true, order: 8),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'cbse_class_12',
      familyId: 'cbse',
      categoryId: 'school_boards_olympiads',
      title: 'Class 12 CBSE',
      authority: 'CBSE',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'node_cbse_c12',
          programId: 'cbse_class_12',
          title: 'Class 12 CBSE',
          children: [
            CatalogLevel(
              id: 'cbse_c12_sci_pcm',
              programId: 'cbse_class_12',
              title: 'Science (PCM)',
              type: CatalogNodeType.stream,
              papers: [
                CatalogPaper(id: 'cbse_c12_pcm_eng', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'English Core', code: '301'),
                CatalogPaper(id: 'cbse_c12_pcm_phy', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'Physics', code: '042'),
                CatalogPaper(id: 'cbse_c12_pcm_chem', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'Chemistry', code: '043'),
                CatalogPaper(id: 'cbse_c12_pcm_math', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'Mathematics', code: '041'),
                CatalogPaper(id: 'cbse_c12_pcm_cs', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'Computer Science', code: '083', type: SubjectRequirementType.elective, isOptional: true),
                CatalogPaper(id: 'cbse_c12_pcm_pe', programId: 'cbse_class_12', levelId: 'cbse_c12_sci_pcm', title: 'Physical Education', code: '048', type: SubjectRequirementType.elective, isOptional: true),
              ],
            ),
            CatalogLevel(
              id: 'cbse_c12_comm_math',
              programId: 'cbse_class_12',
              title: 'Commerce (with Mathematics)',
              type: CatalogNodeType.stream,
              papers: [
                CatalogPaper(id: 'cbse_c12_comm_eng', programId: 'cbse_class_12', levelId: 'cbse_c12_comm_math', title: 'English Core', code: '301'),
                CatalogPaper(id: 'cbse_c12_comm_acc', programId: 'cbse_class_12', levelId: 'cbse_c12_comm_math', title: 'Accountancy', code: '055'),
                CatalogPaper(id: 'cbse_c12_comm_bst', programId: 'cbse_class_12', levelId: 'cbse_c12_comm_math', title: 'Business Studies', code: '054'),
                CatalogPaper(id: 'cbse_c12_comm_eco', programId: 'cbse_class_12', levelId: 'cbse_c12_comm_math', title: 'Economics', code: '030'),
                CatalogPaper(id: 'cbse_c12_comm_math_subj', programId: 'cbse_class_12', levelId: 'cbse_c12_comm_math', title: 'Mathematics', code: '041'),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static const _schoolIcseFamily = CatalogFamily(
    id: 'icse',
    categoryId: 'school_boards_olympiads',
    title: 'CISCE (ICSE / ISC)',
    shortTitle: 'ICSE / ISC',
    programIds: ['icse_class_10', 'isc_class_12'],
  );

  static List<CatalogProgram> _getSchoolICSEPrograms() => [
    CatalogProgram(
      id: 'icse_class_10',
      familyId: 'icse',
      categoryId: 'school_boards_olympiads',
      title: 'Class 10 ICSE',
      authority: 'CISCE',
      levels: [
        CatalogLevel(
          id: 'icse_c10_lvl',
          programId: 'icse_class_10',
          title: 'Class 10 ICSE',
          papers: [
            CatalogPaper(id: 'icse_c10_eng', programId: 'icse_class_10', levelId: 'icse_c10_lvl', title: 'English (Language & Literature)'),
            CatalogPaper(id: 'icse_c10_hcg', programId: 'icse_class_10', levelId: 'icse_c10_lvl', title: 'History, Civics & Geography'),
            CatalogPaper(id: 'icse_c10_math', programId: 'icse_class_10', levelId: 'icse_c10_lvl', title: 'Mathematics'),
            CatalogPaper(id: 'icse_c10_sci', programId: 'icse_class_10', levelId: 'icse_c10_lvl', title: 'Science (Physics, Chemistry, Biology)'),
            CatalogPaper(id: 'icse_c10_ca', programId: 'icse_class_10', levelId: 'icse_c10_lvl', title: 'Computer Applications', isOptional: true),
          ],
        ),
      ],
    ),
  ];

  static const _schoolMhBoardFamily = CatalogFamily(
    id: 'maharashtra_board',
    categoryId: 'school_boards_olympiads',
    title: 'Maharashtra State Board (SSC / HSC)',
    shortTitle: 'Maharashtra Board',
    programIds: ['mh_ssc_class_10', 'mh_hsc_class_12'],
  );

  static List<CatalogProgram> _getSchoolMhBoardPrograms() => [
    CatalogProgram(
      id: 'mh_ssc_class_10',
      familyId: 'maharashtra_board',
      categoryId: 'school_boards_olympiads',
      title: 'Class 10 SSC (Maharashtra State Board)',
      authority: 'Maharashtra State Board',
      levels: [
        CatalogLevel(
          id: 'mh_ssc_lvl',
          programId: 'mh_ssc_class_10',
          title: 'SSC Board Subjects',
          papers: [
            CatalogPaper(id: 'mh_marathi', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'Marathi / First Language'),
            CatalogPaper(id: 'mh_hindi', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'Hindi / Second Language'),
            CatalogPaper(id: 'mh_eng', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'English (Third Language)'),
            CatalogPaper(id: 'mh_math', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'Mathematics (Algebra & Geometry)'),
            CatalogPaper(id: 'mh_sci', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'Science and Technology'),
            CatalogPaper(id: 'mh_sst', programId: 'mh_ssc_class_10', levelId: 'mh_ssc_lvl', title: 'Social Sciences (History, Civics, Geography)'),
          ],
        ),
      ],
    ),
  ];
}
