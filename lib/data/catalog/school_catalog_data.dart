import '../models/catalog/catalog_course.dart';
import '../models/catalog/catalog_curriculum.dart';
import '../models/catalog/catalog_node.dart';
import '../models/catalog/catalog_subject.dart';
import '../models/catalog/course_category.dart';

/// Pre-populated authoritative catalog dataset for School (Classes 1–10)
/// and Senior Secondary (Classes 11–12) education in India.
abstract final class SchoolCatalogData {
  static const String currentVersion = '2024-2025';

  /// Returns all standardized school and senior secondary catalog courses.
  static List<CatalogCourse> getAllSchoolCourses() {
    return [
      ...getPrimaryCourses(),
      ...getMiddleCourses(),
      ...getSecondaryCourses(),
      ...getSeniorSecondaryCourses(),
    ];
  }

  // ─── 1. Primary School (Classes 1–5) ─────────────────────────────────────

  static List<CatalogCourse> getPrimaryCourses() {
    return [
      CatalogCourse(
        id: 'cbse_primary',
        name: 'Primary School (Classes 1–5)',
        category: CourseCategory.school,
        authority: 'CBSE / NCERT',
        catalogVersion: currentVersion,
        description: 'Foundational primary education based on NCERT / CBSE curriculum.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_primary_2024',
            courseId: 'cbse_primary',
            versionCode: currentVersion,
            name: 'CBSE Primary Curriculum ($currentVersion)',
            structure: [
              _buildPrimaryClassNode(1, hasEvs: true),
              _buildPrimaryClassNode(2, hasEvs: true),
              _buildPrimaryClassNode(3, hasEvs: true, hasComputers: true),
              _buildPrimaryClassNode(4, hasEvs: true, hasComputers: true),
              _buildPrimaryClassNode(5, hasEvs: true, hasComputers: true),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'icse_primary',
        name: 'ICSE Primary School (Classes 1–5)',
        category: CourseCategory.school,
        authority: 'CISCE',
        catalogVersion: currentVersion,
        description: 'Primary curriculum based on CISCE guidelines.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_icse_primary_2024',
            courseId: 'icse_primary',
            versionCode: currentVersion,
            name: 'ICSE Primary Curriculum ($currentVersion)',
            structure: [
              _buildPrimaryClassNode(1, isIcse: true, hasEvs: true),
              _buildPrimaryClassNode(2, isIcse: true, hasEvs: true),
              _buildPrimaryClassNode(3, isIcse: true, hasEvs: true, hasComputers: true),
              _buildPrimaryClassNode(4, isIcse: true, hasEvs: true, hasComputers: true),
              _buildPrimaryClassNode(5, isIcse: true, hasEvs: true, hasComputers: true),
            ],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildPrimaryClassNode(
    int classNum, {
    bool isIcse = false,
    bool hasEvs = true,
    bool hasComputers = false,
  }) {
    final prefix = isIcse ? 'icse_c$classNum' : 'cbse_c$classNum';
    final subjects = <CatalogSubject>[
      CatalogSubject(
        id: '${prefix}_eng',
        name: 'English',
        type: SubjectRequirementType.compulsory,
      ),
      CatalogSubject(
        id: '${prefix}_math',
        name: 'Mathematics',
        type: SubjectRequirementType.compulsory,
      ),
      if (hasEvs)
        CatalogSubject(
          id: '${prefix}_evs',
          name: 'Environmental Studies (EVS)',
          type: SubjectRequirementType.compulsory,
        ),
      CatalogSubject(
        id: '${prefix}_lang2',
        name: 'Hindi / Second Language',
        type: SubjectRequirementType.compulsory,
      ),
      if (hasComputers)
        CatalogSubject(
          id: '${prefix}_comp',
          name: 'Computer Studies',
          type: SubjectRequirementType.optional,
        ),
      CatalogSubject(
        id: '${prefix}_art',
        name: 'Art & Craft',
        type: SubjectRequirementType.optional,
      ),
    ];

    return CatalogNode(
      id: isIcse ? 'node_icse_class_$classNum' : 'node_cbse_class_$classNum',
      name: 'Class $classNum',
      type: CatalogNodeType.level,
      sortOrder: classNum,
      subjects: subjects,
    );
  }

  // ─── 2. Middle School (Classes 6–8) ──────────────────────────────────────

  static List<CatalogCourse> getMiddleCourses() {
    return [
      CatalogCourse(
        id: 'cbse_middle',
        name: 'Middle School (Classes 6–8)',
        category: CourseCategory.school,
        authority: 'CBSE / NCERT',
        catalogVersion: currentVersion,
        description: 'Upper primary middle school curriculum under CBSE / NCERT.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_middle_2024',
            courseId: 'cbse_middle',
            versionCode: currentVersion,
            name: 'CBSE Middle School Curriculum ($currentVersion)',
            structure: [
              _buildMiddleClassNode(6),
              _buildMiddleClassNode(7),
              _buildMiddleClassNode(8),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'icse_middle',
        name: 'ICSE Middle School (Classes 6–8)',
        category: CourseCategory.school,
        authority: 'CISCE',
        catalogVersion: currentVersion,
        description: 'Middle school curriculum under CISCE.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_icse_middle_2024',
            courseId: 'icse_middle',
            versionCode: currentVersion,
            name: 'ICSE Middle School Curriculum ($currentVersion)',
            structure: [
              _buildIcseMiddleClassNode(6),
              _buildIcseMiddleClassNode(7),
              _buildIcseMiddleClassNode(8),
            ],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildMiddleClassNode(int classNum) {
    final prefix = 'cbse_c$classNum';
    return CatalogNode(
      id: 'node_cbse_class_$classNum',
      name: 'Class $classNum',
      type: CatalogNodeType.level,
      sortOrder: classNum,
      subjects: [
        CatalogSubject(
          id: '${prefix}_eng',
          name: 'English',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_math',
          name: 'Mathematics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_sci',
          name: 'Science',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_sst',
          name: 'Social Science',
          description: 'History, Civics, Geography',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_lang2',
          name: 'Hindi / Second Language',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_lang3',
          name: 'Third Language (Sanskrit / Regional / Foreign)',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_ict',
          name: 'Information & Communication Technology (ICT)',
          type: SubjectRequirementType.optional,
        ),
      ],
    );
  }

  static CatalogNode _buildIcseMiddleClassNode(int classNum) {
    final prefix = 'icse_c$classNum';
    return CatalogNode(
      id: 'node_icse_class_$classNum',
      name: 'Class $classNum',
      type: CatalogNodeType.level,
      sortOrder: classNum,
      subjects: [
        CatalogSubject(
          id: '${prefix}_eng',
          name: 'English',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_math',
          name: 'Mathematics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_physics',
          name: 'Physics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_chemistry',
          name: 'Chemistry',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_biology',
          name: 'Biology',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_history_civics',
          name: 'History & Civics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_geography',
          name: 'Geography',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_lang2',
          name: 'Second Language',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_comp',
          name: 'Computer Applications',
          type: SubjectRequirementType.optional,
        ),
      ],
    );
  }

  // ─── 3. Secondary School (Classes 9–10) ───────────────────────────────────

  static List<CatalogCourse> getSecondaryCourses() {
    return [
      CatalogCourse(
        id: 'cbse_class_9',
        name: 'Class 9 CBSE',
        category: CourseCategory.school,
        authority: 'CBSE',
        catalogVersion: currentVersion,
        description: 'Secondary school curriculum for Class 9 under CBSE.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_9_2024',
            courseId: 'cbse_class_9',
            versionCode: currentVersion,
            name: 'CBSE Class 9 Curriculum ($currentVersion)',
            structure: [_buildCbseSecondaryNode(9)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cbse_class_10',
        name: 'Class 10 CBSE',
        category: CourseCategory.school,
        authority: 'CBSE',
        catalogVersion: currentVersion,
        description: 'Secondary School Board Examination curriculum under CBSE.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_10_2024',
            courseId: 'cbse_class_10',
            versionCode: currentVersion,
            name: 'CBSE Class 10 Curriculum ($currentVersion)',
            structure: [_buildCbseSecondaryNode(10)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'icse_class_10',
        name: 'Class 10 ICSE',
        category: CourseCategory.school,
        authority: 'CISCE',
        catalogVersion: currentVersion,
        description: 'Indian Certificate of Secondary Education (ICSE Class 10).',
        curricula: [
          CatalogCurriculum(
            id: 'curr_icse_10_2024',
            courseId: 'icse_class_10',
            versionCode: currentVersion,
            name: 'ICSE Class 10 Curriculum ($currentVersion)',
            structure: [_buildIcseClass10Node()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'state_board_class_10',
        name: 'Class 10 State Board',
        category: CourseCategory.school,
        authority: 'State Board',
        catalogVersion: currentVersion,
        description: 'Standard Secondary School Leaving Certificate (SSLC) / State Board syllabus.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_state_10_2024',
            courseId: 'state_board_class_10',
            versionCode: currentVersion,
            name: 'State Board Class 10 Curriculum ($currentVersion)',
            structure: [_buildStateBoardClass10Node()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildCbseSecondaryNode(int classNum) {
    final prefix = 'cbse_c$classNum';
    return CatalogNode(
      id: 'node_cbse_class_$classNum',
      name: 'Class $classNum',
      type: CatalogNodeType.level,
      subjects: [
        // 5 Compulsory Subjects
        CatalogSubject(
          id: '${prefix}_eng_lang_lit',
          name: 'English Language and Literature',
          code: '184',
          shortName: 'English',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_math_std',
          name: 'Mathematics (Standard)',
          code: '041',
          shortName: 'Maths Std',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_math_basic',
          name: 'Mathematics (Basic)',
          code: '241',
          shortName: 'Maths Basic',
          type: SubjectRequirementType.elective,
          description: 'Alternative to standard mathematics for students not pursuing math in 11/12',
        ),
        CatalogSubject(
          id: '${prefix}_science',
          name: 'Science',
          code: '086',
          shortName: 'Science',
          description: 'Physics, Chemistry, Biology integrated',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_social_science',
          name: 'Social Science',
          code: '087',
          shortName: 'Social Science',
          description: 'History, Geography, Political Science, Economics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_hindi_a',
          name: 'Hindi Course-A',
          code: '002',
          shortName: 'Hindi-A',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_hindi_b',
          name: 'Hindi Course-B',
          code: '085',
          shortName: 'Hindi-B',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_sanskrit',
          name: 'Sanskrit',
          code: '122',
          shortName: 'Sanskrit',
          type: SubjectRequirementType.elective,
        ),
        // Skill / 6th Subject Electives
        CatalogSubject(
          id: '${prefix}_it',
          name: 'Information Technology',
          code: '402',
          shortName: 'IT',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_ai',
          name: 'Artificial Intelligence',
          code: '417',
          shortName: 'AI',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_fin_markets',
          name: 'Introduction to Financial Markets',
          code: '405',
          shortName: 'Financial Markets',
          type: SubjectRequirementType.elective,
        ),
        CatalogSubject(
          id: '${prefix}_comp_app',
          name: 'Computer Applications',
          code: '165',
          shortName: 'Computer App',
          type: SubjectRequirementType.elective,
        ),
      ],
    );
  }

  static CatalogNode _buildIcseClass10Node() {
    const prefix = 'icse_c10';
    return CatalogNode(
      id: 'node_icse_class_10',
      name: 'Class 10 ICSE',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: '${prefix}_group1',
          name: 'Group I (Compulsory Subjects)',
          type: CatalogNodeType.group,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English (Language & Literature)',
              code: 'ENG',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_lang2',
              name: 'Second Language (Hindi / Regional)',
              code: 'L2',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_hcg',
              name: 'History, Civics & Geography',
              code: 'HCG',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_group2',
          name: 'Group II (Select Any 2 or 3)',
          type: CatalogNodeType.group,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              code: 'MATH',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_science',
              name: 'Science (Physics, Chemistry, Biology)',
              code: 'SCI',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_commercial_studies',
              name: 'Commercial Studies',
              code: 'CMS',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_economics',
              name: 'Economics',
              code: 'ECO',
              type: SubjectRequirementType.elective,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_group3',
          name: 'Group III (Select Any 1 Elective)',
          type: CatalogNodeType.group,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_comp_app',
              name: 'Computer Applications',
              code: 'CA',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: '${prefix}_comm_app',
              name: 'Commercial Applications',
              code: 'CMA',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: '${prefix}_phys_ed',
              name: 'Physical Education',
              code: 'PE',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: '${prefix}_art',
              name: 'Art',
              code: 'ART',
              type: SubjectRequirementType.optional,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildStateBoardClass10Node() {
    const prefix = 'state_c10';
    return CatalogNode(
      id: 'node_state_class_10',
      name: 'Class 10 State Board',
      type: CatalogNodeType.level,
      subjects: const [
        CatalogSubject(
          id: '${prefix}_lang1',
          name: 'First Language / Regional Language',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_lang2',
          name: 'Second Language / Hindi',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_eng',
          name: 'English (Third Language)',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_math',
          name: 'Mathematics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_science',
          name: 'General Science',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: '${prefix}_social',
          name: 'Social Science',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  // ─── 4. Senior Secondary (Classes 11–12) ──────────────────────────────────

  static List<CatalogCourse> getSeniorSecondaryCourses() {
    return [
      CatalogCourse(
        id: 'cbse_class_11',
        name: 'Class 11 CBSE',
        category: CourseCategory.seniorSecondary,
        authority: 'CBSE',
        catalogVersion: currentVersion,
        description: 'Senior Secondary Year 1 under CBSE with Science, Commerce, and Humanities streams.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_11_2024',
            courseId: 'cbse_class_11',
            versionCode: currentVersion,
            name: 'CBSE Class 11 Curriculum ($currentVersion)',
            structure: [_buildSeniorSecondaryNode(11, 'CBSE')],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cbse_class_12',
        name: 'Class 12 CBSE',
        category: CourseCategory.seniorSecondary,
        authority: 'CBSE',
        catalogVersion: currentVersion,
        description: 'Senior School Certificate Examination (Class 12) under CBSE.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cbse_12_2024',
            courseId: 'cbse_class_12',
            versionCode: currentVersion,
            name: 'CBSE Class 12 Curriculum ($currentVersion)',
            structure: [_buildSeniorSecondaryNode(12, 'CBSE')],
          ),
        ],
      ),
      CatalogCourse(
        id: 'isc_class_12',
        name: 'Class 12 ISC',
        category: CourseCategory.seniorSecondary,
        authority: 'CISCE',
        catalogVersion: currentVersion,
        description: 'Indian School Certificate (ISC Class 12) under CISCE.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_isc_12_2024',
            courseId: 'isc_class_12',
            versionCode: currentVersion,
            name: 'ISC Class 12 Curriculum ($currentVersion)',
            structure: [_buildIscSeniorSecondaryNode(12)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'state_board_class_12',
        name: 'Class 12 State Board (HSC / PUC)',
        category: CourseCategory.seniorSecondary,
        authority: 'State Board',
        catalogVersion: currentVersion,
        description: 'Higher Secondary Certificate (HSC / PUC II) state board curriculum.',
        curricula: [
          CatalogCurriculum(
            id: 'curr_state_12_2024',
            courseId: 'state_board_class_12',
            versionCode: currentVersion,
            name: 'State Board Class 12 Curriculum ($currentVersion)',
            structure: [_buildStateBoardSeniorSecondaryNode(12)],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildSeniorSecondaryNode(int classNum, String board) {
    final prefix = 'cbse_c$classNum';

    // Core common electives
    final commonElectives = [
      CatalogSubject(
        id: '${prefix}_pe',
        name: 'Physical Education',
        code: '048',
        shortName: 'Physical Ed',
        type: SubjectRequirementType.elective,
      ),
      CatalogSubject(
        id: '${prefix}_cs',
        name: 'Computer Science',
        code: '083',
        shortName: 'Comp Science',
        type: SubjectRequirementType.elective,
      ),
      CatalogSubject(
        id: '${prefix}_ip',
        name: 'Informatics Practices',
        code: '065',
        shortName: 'Informatics',
        type: SubjectRequirementType.elective,
      ),
      CatalogSubject(
        id: '${prefix}_hindi_core',
        name: 'Hindi Core',
        code: '302',
        shortName: 'Hindi Core',
        type: SubjectRequirementType.optional,
      ),
      CatalogSubject(
        id: '${prefix}_painting',
        name: 'Painting / Fine Arts',
        code: '049',
        shortName: 'Painting',
        type: SubjectRequirementType.optional,
      ),
    ];

    return CatalogNode(
      id: 'node_cbse_c$classNum',
      name: 'Class $classNum $board',
      type: CatalogNodeType.level,
      children: [
        // ── Science: PCM ──
        CatalogNode(
          id: '${prefix}_sci_pcm',
          name: 'Science (PCM)',
          type: CatalogNodeType.stream,
          description: 'Physics, Chemistry, Mathematics with technical/general electives',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_physics',
              name: 'Physics',
              code: '042',
              shortName: 'Physics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_chem',
              name: 'Chemistry',
              code: '043',
              shortName: 'Chemistry',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              code: '041',
              shortName: 'Mathematics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_eco_elective',
              name: 'Economics',
              code: '030',
              shortName: 'Economics',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),

        // ── Science: PCB ──
        CatalogNode(
          id: '${prefix}_sci_pcb',
          name: 'Science (PCB)',
          type: CatalogNodeType.stream,
          description: 'Physics, Chemistry, Biology with medical/general electives',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_physics',
              name: 'Physics',
              code: '042',
              shortName: 'Physics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_chem',
              name: 'Chemistry',
              code: '043',
              shortName: 'Chemistry',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_bio',
              name: 'Biology',
              code: '044',
              shortName: 'Biology',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_psychology',
              name: 'Psychology',
              code: '037',
              shortName: 'Psychology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_biotech',
              name: 'Biotechnology',
              code: '045',
              shortName: 'Biotechnology',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),

        // ── Science: PCMB ──
        CatalogNode(
          id: '${prefix}_sci_pcmb',
          name: 'Science (PCMB)',
          type: CatalogNodeType.stream,
          description: 'Physics, Chemistry, Mathematics, Biology combined',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_physics',
              name: 'Physics',
              code: '042',
              shortName: 'Physics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_chem',
              name: 'Chemistry',
              code: '043',
              shortName: 'Chemistry',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              code: '041',
              shortName: 'Mathematics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_bio',
              name: 'Biology',
              code: '044',
              shortName: 'Biology',
              type: SubjectRequirementType.compulsory,
            ),
            ...commonElectives,
          ],
        ),

        // ── Commerce with Mathematics ──
        CatalogNode(
          id: '${prefix}_comm_math',
          name: 'Commerce (with Mathematics)',
          type: CatalogNodeType.stream,
          description: 'Accountancy, Business Studies, Economics, and Core Mathematics (041)',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_acc',
              name: 'Accountancy',
              code: '055',
              shortName: 'Accountancy',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_bst',
              name: 'Business Studies',
              code: '054',
              shortName: 'Business Studies',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_eco',
              name: 'Economics',
              code: '030',
              shortName: 'Economics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              code: '041',
              shortName: 'Mathematics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_ent',
              name: 'Entrepreneurship',
              code: '066',
              shortName: 'Entrepreneurship',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),

        // ── Commerce with Applied Mathematics ──
        CatalogNode(
          id: '${prefix}_comm_applied_math',
          name: 'Commerce (with Applied Mathematics)',
          type: CatalogNodeType.stream,
          description: 'Accountancy, Business Studies, Economics, and Applied Mathematics (241)',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_acc',
              name: 'Accountancy',
              code: '055',
              shortName: 'Accountancy',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_bst',
              name: 'Business Studies',
              code: '054',
              shortName: 'Business Studies',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_eco',
              name: 'Economics',
              code: '030',
              shortName: 'Economics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_applied_math',
              name: 'Applied Mathematics',
              code: '241',
              shortName: 'Applied Maths',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_ent',
              name: 'Entrepreneurship',
              code: '066',
              shortName: 'Entrepreneurship',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),

        // ── Commerce without Mathematics ──
        CatalogNode(
          id: '${prefix}_comm_no_math',
          name: 'Commerce (without Mathematics)',
          type: CatalogNodeType.stream,
          description: 'Accountancy, Business Studies, Economics with Informatics/Entrepreneurship/PE',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_acc',
              name: 'Accountancy',
              code: '055',
              shortName: 'Accountancy',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_bst',
              name: 'Business Studies',
              code: '054',
              shortName: 'Business Studies',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_eco',
              name: 'Economics',
              code: '030',
              shortName: 'Economics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_ent',
              name: 'Entrepreneurship',
              code: '066',
              shortName: 'Entrepreneurship',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_legal_studies',
              name: 'Legal Studies',
              code: '074',
              shortName: 'Legal Studies',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),

        // ── Humanities / Arts ──
        CatalogNode(
          id: '${prefix}_humanities',
          name: 'Humanities / Arts',
          type: CatalogNodeType.stream,
          description: 'Social sciences, languages, and liberal arts electives',
          subjects: [
            CatalogSubject(
              id: '${prefix}_eng_core',
              name: 'English Core',
              code: '301',
              shortName: 'English Core',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_history',
              name: 'History',
              code: '027',
              shortName: 'History',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_pol_sci',
              name: 'Political Science',
              code: '028',
              shortName: 'Political Science',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_geography',
              name: 'Geography',
              code: '029',
              shortName: 'Geography',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_eco',
              name: 'Economics',
              code: '030',
              shortName: 'Economics',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_psychology',
              name: 'Psychology',
              code: '037',
              shortName: 'Psychology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_sociology',
              name: 'Sociology',
              code: '039',
              shortName: 'Sociology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_legal_studies',
              name: 'Legal Studies',
              code: '074',
              shortName: 'Legal Studies',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_applied_math',
              name: 'Applied Mathematics',
              code: '241',
              shortName: 'Applied Maths',
              type: SubjectRequirementType.elective,
            ),
            ...commonElectives,
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildIscSeniorSecondaryNode(int classNum) {
    const prefix = 'isc_c12';
    return CatalogNode(
      id: 'node_isc_class_$classNum',
      name: 'Class $classNum ISC',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: '${prefix}_science',
          name: 'Science Stream (ISC)',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English (Compulsory)',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_physics',
              name: 'Physics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_chemistry',
              name: 'Chemistry',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_biology',
              name: 'Biology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_cs',
              name: 'Computer Science',
              type: SubjectRequirementType.optional,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_commerce',
          name: 'Commerce Stream (ISC)',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English (Compulsory)',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_accounts',
              name: 'Accounts',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_commerce_subj',
              name: 'Commerce',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_economics',
              name: 'Economics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_business_studies',
              name: 'Business Studies',
              type: SubjectRequirementType.elective,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_humanities',
          name: 'Humanities Stream (ISC)',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English (Compulsory)',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_history',
              name: 'History',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_political_science',
              name: 'Political Science',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_geography',
              name: 'Geography',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_sociology',
              name: 'Sociology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_psychology',
              name: 'Psychology',
              type: SubjectRequirementType.elective,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildStateBoardSeniorSecondaryNode(int classNum) {
    const prefix = 'state_c12';
    return CatalogNode(
      id: 'node_state_class_$classNum',
      name: 'Class $classNum State Board (HSC / PUC)',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: '${prefix}_science',
          name: 'Science Stream (PCMB / PCMC)',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_lang2',
              name: 'Second Language / Regional Language',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_physics',
              name: 'Physics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_chemistry',
              name: 'Chemistry',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Mathematics',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_bio',
              name: 'Biology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_cs',
              name: 'Computer Science',
              type: SubjectRequirementType.optional,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_commerce',
          name: 'Commerce Stream (HEBA / CEBA)',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_lang2',
              name: 'Second Language / Regional Language',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_accountancy',
              name: 'Accountancy / Book-keeping',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_business_studies',
              name: 'Business Studies / Commerce',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_economics',
              name: 'Economics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_math',
              name: 'Business Mathematics / Statistics',
              type: SubjectRequirementType.elective,
            ),
          ],
        ),
        CatalogNode(
          id: '${prefix}_arts',
          name: 'Arts / Humanities Stream',
          type: CatalogNodeType.stream,
          subjects: const [
            CatalogSubject(
              id: '${prefix}_eng',
              name: 'English',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_lang2',
              name: 'Second Language / Regional Language',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: '${prefix}_history',
              name: 'History',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_pol_sci',
              name: 'Political Science',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_sociology',
              name: 'Sociology',
              type: SubjectRequirementType.elective,
            ),
            CatalogSubject(
              id: '${prefix}_geography',
              name: 'Geography',
              type: SubjectRequirementType.elective,
            ),
          ],
        ),
      ],
    );
  }
}
