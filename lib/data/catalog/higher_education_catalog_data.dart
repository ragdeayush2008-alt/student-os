import '../models/catalog/catalog_course.dart';
import '../models/catalog/catalog_curriculum.dart';
import '../models/catalog/catalog_node.dart';
import '../models/catalog/catalog_subject.dart';
import '../models/catalog/course_category.dart';

abstract final class HigherEducationCatalogData {
  static const String currentVersion = '2025-2026';

  static List<CatalogCourse> getAllHigherEducationCourses() {
    return [
      ...getUndergraduateCourses(),
      ...getPostgraduateCourses(),
    ];
  }

  static List<CatalogCourse> getUndergraduateCourses() {
    return [
      ...getCommerceUGCourses(),
      ...getArtsHumanitiesUGCourses(),
      ...getScienceUGCourses(),
      ...getComputerITUGCourses(),
      ...getEngineeringUGCourses(),
      ...getLawUGCourses(),
      ...getHealthcareUGCourses(),
      ...getDesignArchitectureUGCourses(),
    ];
  }

  static List<CatalogCourse> getPostgraduateCourses() {
    return [
      ...getCommercePGCourses(),
      ...getArtsPGCourses(),
      ...getSciencePGCourses(),
      ...getComputerITPGCourses(),
      ...getEngineeringPGCourses(),
      ...getLawPGCourses(),
      ...getDesignPGCourses(),
    ];
  }

  static List<CatalogCourse> getCommerceUGCourses() {
    return [
      CatalogCourse(
        id: 'bcom',
        name: 'B.Com',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Commerce',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bcom_2025',
            courseId: 'bcom',
            versionCode: currentVersion,
            name: 'B.Com Curriculum ($currentVersion)',
            structure: [
              _buildBComYear(1),
              _buildBComYear(2),
              _buildBComYear(3),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'bba',
        name: 'BBA',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Business Administration',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bba_2025',
            courseId: 'bba',
            versionCode: currentVersion,
            name: 'BBA Curriculum ($currentVersion)',
            structure: [
              _buildBBAYear(1),
              _buildBBAYear(2),
              _buildBBAYear(3),
            ],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildBComYear(int year) {
    final prefix = 'bcom_y$year';
    return CatalogNode(
      id: 'node_bcom_year_$year',
      name: 'Year $year',
      type: CatalogNodeType.year,
      sortOrder: year,
      children: [
        CatalogNode(
          id: '${prefix}_sem1',
          name: 'Semester ${year * 2 - 1}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2 - 1,
          subjects: _getBComSemesterSubjects(year, 1),
        ),
        CatalogNode(
          id: '${prefix}_sem2',
          name: 'Semester ${year * 2}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2,
          subjects: _getBComSemesterSubjects(year, 2),
        ),
      ],
    );
  }

  static List<CatalogSubject> _getBComSemesterSubjects(int year, int sem) {
    final prefix = 'bcom_y${year}_s$sem';
    if (year == 1 && sem == 1) {
      return [
        CatalogSubject(id: '${prefix}_fin_acc', name: 'Financial Accounting', type: SubjectRequirementType.compulsory),
        CatalogSubject(id: '${prefix}_bus_comm', name: 'Business Communication', type: SubjectRequirementType.compulsory),
        CatalogSubject(id: '${prefix}_micro_eco', name: 'Microeconomics', type: SubjectRequirementType.compulsory),
        CatalogSubject(id: '${prefix}_bus_law', name: 'Business Law', type: SubjectRequirementType.compulsory),
      ];
    }
    return [
      CatalogSubject(id: '${prefix}_core', name: 'Core Commerce Subject', type: SubjectRequirementType.compulsory),
    ];
  }

  static CatalogNode _buildBBAYear(int year) {
    final prefix = 'bba_y$year';
    return CatalogNode(
      id: 'node_bba_year_$year',
      name: 'Year $year',
      type: CatalogNodeType.year,
      sortOrder: year,
      children: [
        CatalogNode(
          id: '${prefix}_sem1',
          name: 'Semester ${year * 2 - 1}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2 - 1,
          subjects: [
            CatalogSubject(id: '${prefix}_s1_core', name: 'Business Management Fundamentals', type: SubjectRequirementType.compulsory),
          ],
        ),
        CatalogNode(
          id: '${prefix}_sem2',
          name: 'Semester ${year * 2}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2,
          subjects: [
            CatalogSubject(id: '${prefix}_s2_core', name: 'Business Operations', type: SubjectRequirementType.compulsory),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getArtsHumanitiesUGCourses() {
    return [
      CatalogCourse(
        id: 'ba',
        name: 'BA',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_2025',
            courseId: 'ba',
            versionCode: currentVersion,
            name: 'BA Curriculum ($currentVersion)',
            structure: [
              _buildBAYear(1),
              _buildBAYear(2),
              _buildBAYear(3),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_english',
        name: 'BA English',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in English',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_eng_2025',
            courseId: 'ba_english',
            versionCode: currentVersion,
            name: 'BA English Curriculum ($currentVersion)',
            structure: [
              _buildBAEnglishYear(1),
              _buildBAEnglishYear(2),
              _buildBAEnglishYear(3),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_economics',
        name: 'BA Economics',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in Economics',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_eco_2025',
            courseId: 'ba_economics',
            versionCode: currentVersion,
            name: 'BA Economics Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_eco', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_psychology',
        name: 'BA Psychology',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in Psychology',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_psy_2025',
            courseId: 'ba_psychology',
            versionCode: currentVersion,
            name: 'BA Psychology Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_psy', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_history',
        name: 'BA History',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in History',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_hist_2025',
            courseId: 'ba_history',
            versionCode: currentVersion,
            name: 'BA History Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_hist', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_political_science',
        name: 'BA Political Science',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in Political Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_pol_2025',
            courseId: 'ba_political_science',
            versionCode: currentVersion,
            name: 'BA Political Science Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_pol', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_sociology',
        name: 'BA Sociology',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in Sociology',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_soc_2025',
            courseId: 'ba_sociology',
            versionCode: currentVersion,
            name: 'BA Sociology Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_soc', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_geography',
        name: 'BA Geography',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Arts in Geography',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_geo_2025',
            courseId: 'ba_geography',
            versionCode: currentVersion,
            name: 'BA Geography Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('ba_geo', 3)],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildBAYear(int year) {
    final prefix = 'ba_y$year';
    return CatalogNode(
      id: 'node_ba_year_$year',
      name: 'Year $year',
      type: CatalogNodeType.year,
      sortOrder: year,
      children: [
        CatalogNode(
          id: '${prefix}_sem1',
          name: 'Semester ${year * 2 - 1}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2 - 1,
          subjects: [
            CatalogSubject(id: '${prefix}_s1_major', name: 'Major Subject', type: SubjectRequirementType.compulsory),
            CatalogSubject(id: '${prefix}_s1_elec', name: 'Elective', type: SubjectRequirementType.elective),
          ],
        ),
        CatalogNode(
          id: '${prefix}_sem2',
          name: 'Semester ${year * 2}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2,
          subjects: [
            CatalogSubject(id: '${prefix}_s2_major', name: 'Major Subject', type: SubjectRequirementType.compulsory),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildBAEnglishYear(int year) {
    final prefix = 'ba_eng_y$year';
    return CatalogNode(
      id: 'node_ba_eng_year_$year',
      name: 'Year $year',
      type: CatalogNodeType.year,
      sortOrder: year,
      children: [
        CatalogNode(
          id: '${prefix}_sem1',
          name: 'Semester ${year * 2 - 1}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2 - 1,
          subjects: [
            CatalogSubject(id: '${prefix}_s1_lit', name: 'English Literature', type: SubjectRequirementType.compulsory),
            CatalogSubject(id: '${prefix}_s1_lang', name: 'English Language', type: SubjectRequirementType.compulsory),
          ],
        ),
        CatalogNode(
          id: '${prefix}_sem2',
          name: 'Semester ${year * 2}',
          type: CatalogNodeType.semester,
          sortOrder: year * 2,
          subjects: [
            CatalogSubject(id: '${prefix}_s2_lit', name: 'English Literature', type: SubjectRequirementType.compulsory),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildGenericYearStructure(String prefix, int years) {
    return CatalogNode(
      id: 'node_${prefix}_structure',
      name: 'Course Structure',
      type: CatalogNodeType.level,
      children: List.generate(
        years,
        (i) {
          final year = i + 1;
          return CatalogNode(
            id: 'node_${prefix}_year_$year',
            name: 'Year $year',
            type: CatalogNodeType.year,
            sortOrder: year,
            children: [
              CatalogNode(
                id: '${prefix}_y${year}_sem1',
                name: 'Semester ${year * 2 - 1}',
                type: CatalogNodeType.semester,
                sortOrder: year * 2 - 1,
                subjects: [
                  CatalogSubject(id: '${prefix}_y${year}_s1_core', name: 'Core Subject', type: SubjectRequirementType.compulsory),
                ],
              ),
              CatalogNode(
                id: '${prefix}_y${year}_sem2',
                name: 'Semester ${year * 2}',
                type: CatalogNodeType.semester,
                sortOrder: year * 2,
                subjects: [
                  CatalogSubject(id: '${prefix}_y${year}_s2_core', name: 'Core Subject', type: SubjectRequirementType.compulsory),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static List<CatalogCourse> getScienceUGCourses() {
    return [
      CatalogCourse(
        id: 'bsc',
        name: 'B.Sc',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bsc_2025',
            courseId: 'bsc',
            versionCode: currentVersion,
            name: 'B.Sc Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('bsc', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'bsc_mathematics',
        name: 'B.Sc Mathematics',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science in Mathematics',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bsc_math_2025',
            courseId: 'bsc_mathematics',
            versionCode: currentVersion,
            name: 'B.Sc Mathematics Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('bsc_math', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'bsc_physics',
        name: 'B.Sc Physics',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science in Physics',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bsc_phy_2025',
            courseId: 'bsc_physics',
            versionCode: currentVersion,
            name: 'B.Sc Physics Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('bsc_phy', 3)],
          ),
        ],
      ),
      CatalogCourse(
        id: 'bsc_chemistry',
        name: 'B.Sc Chemistry',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science in Chemistry',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bsc_chem_2025',
            courseId: 'bsc_chemistry',
            versionCode: currentVersion,
            name: 'B.Sc Chemistry Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('bsc_chem', 3)],
          ),
        ],
      ),
    ];
  }

  static List<CatalogCourse> getComputerITUGCourses() {
    return [
      CatalogCourse(
        id: 'bca',
        name: 'BCA',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Computer Applications',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bca_2025',
            courseId: 'bca',
            versionCode: currentVersion,
            name: 'BCA Curriculum ($currentVersion)',
            structure: [
              _buildBCASemester(1),
              _buildBCASemester(2),
              _buildBCASemester(3),
              _buildBCASemester(4),
              _buildBCASemester(5),
              _buildBCASemester(6),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'bsc_computer_science',
        name: 'B.Sc Computer Science',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science in Computer Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bsc_cs_2025',
            courseId: 'bsc_computer_science',
            versionCode: currentVersion,
            name: 'B.Sc Computer Science Curriculum ($currentVersion)',
            structure: [_buildGenericYearStructure('bsc_cs', 3)],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildBCASemester(int sem) {
    final prefix = 'bca_sem$sem';
    return CatalogNode(
      id: 'node_bca_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        if (sem == 1) ...[
          CatalogSubject(id: '${prefix}_prog', name: 'Programming Fundamentals', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_math', name: 'Mathematics', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_digital', name: 'Digital Electronics', type: SubjectRequirementType.compulsory),
        ] else ...[
          CatalogSubject(id: '${prefix}_core', name: 'Core Computer Subject', type: SubjectRequirementType.compulsory),
        ],
      ],
    );
  }

  static List<CatalogCourse> getEngineeringUGCourses() {
    return [
      CatalogCourse(
        id: 'btech_cse',
        name: 'B.Tech Computer Science',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Computer Science & Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_cse_2025',
            courseId: 'btech_cse',
            versionCode: currentVersion,
            name: 'B.Tech CSE Curriculum ($currentVersion)',
            structure: [
              _buildBTechSemester('cse', 1),
              _buildBTechSemester('cse', 2),
              _buildBTechSemester('cse', 3),
              _buildBTechSemester('cse', 4),
              _buildBTechSemester('cse', 5),
              _buildBTechSemester('cse', 6),
              _buildBTechSemester('cse', 7),
              _buildBTechSemester('cse', 8),
            ],
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_it',
        name: 'B.Tech Information Technology',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Information Technology',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_it_2025',
            courseId: 'btech_it',
            versionCode: currentVersion,
            name: 'B.Tech IT Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('it', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_aiml',
        name: 'B.Tech Artificial Intelligence & Machine Learning',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in AI & ML',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_aiml_2025',
            courseId: 'btech_aiml',
            versionCode: currentVersion,
            name: 'B.Tech AI-ML Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('aiml', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_ds',
        name: 'B.Tech Data Science',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Data Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_ds_2025',
            courseId: 'btech_ds',
            versionCode: currentVersion,
            name: 'B.Tech Data Science Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('ds', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_ece',
        name: 'B.Tech Electronics & Communication',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Electronics & Communication Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_ece_2025',
            courseId: 'btech_ece',
            versionCode: currentVersion,
            name: 'B.Tech ECE Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('ece', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_ee',
        name: 'B.Tech Electrical',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Electrical Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_ee_2025',
            courseId: 'btech_ee',
            versionCode: currentVersion,
            name: 'B.Tech EE Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('ee', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_me',
        name: 'B.Tech Mechanical',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Mechanical Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_me_2025',
            courseId: 'btech_me',
            versionCode: currentVersion,
            name: 'B.Tech Mechanical Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('me', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_civil',
        name: 'B.Tech Civil',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Civil Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_civil_2025',
            courseId: 'btech_civil',
            versionCode: currentVersion,
            name: 'B.Tech Civil Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('civil', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_chemical',
        name: 'B.Tech Chemical',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Chemical Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_chem_2025',
            courseId: 'btech_chemical',
            versionCode: currentVersion,
            name: 'B.Tech Chemical Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('chem', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_biotech',
        name: 'B.Tech Biotechnology',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Biotechnology',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_biotech_2025',
            courseId: 'btech_biotech',
            versionCode: currentVersion,
            name: 'B.Tech Biotechnology Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('biotech', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_aerospace',
        name: 'B.Tech Aerospace',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Aerospace Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_aero_2025',
            courseId: 'btech_aerospace',
            versionCode: currentVersion,
            name: 'B.Tech Aerospace Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('aero', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_automobile',
        name: 'B.Tech Automobile',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Automobile Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_auto_2025',
            courseId: 'btech_automobile',
            versionCode: currentVersion,
            name: 'B.Tech Automobile Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('auto', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_instrumentation',
        name: 'B.Tech Instrumentation',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Instrumentation Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_inst_2025',
            courseId: 'btech_instrumentation',
            versionCode: currentVersion,
            name: 'B.Tech Instrumentation Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('inst', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_robotics',
        name: 'B.Tech Robotics',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Robotics Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_robotics_2025',
            courseId: 'btech_robotics',
            versionCode: currentVersion,
            name: 'B.Tech Robotics Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('robotics', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'btech_biomedical',
        name: 'B.Tech Biomedical',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Technology in Biomedical Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_btech_bme_2025',
            courseId: 'btech_biomedical',
            versionCode: currentVersion,
            name: 'B.Tech Biomedical Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildBTechSemester('bme', i + 1)),
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildBTechSemester(String branch, int sem) {
    final prefix = 'btech_${branch}_sem$sem';
    return CatalogNode(
      id: 'node_btech_${branch}_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        if (sem == 1) ...[
          CatalogSubject(id: '${prefix}_math1', name: 'Engineering Mathematics I', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_phy', name: 'Engineering Physics', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_chem', name: 'Engineering Chemistry', type: SubjectRequirementType.compulsory),
        ] else if (sem == 2) ...[
          CatalogSubject(id: '${prefix}_math2', name: 'Engineering Mathematics II', type: SubjectRequirementType.compulsory),
        ] else ...[
          CatalogSubject(id: '${prefix}_core', name: 'Branch Core Subject', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_elec', name: 'Elective', type: SubjectRequirementType.elective),
        ],
      ],
    );
  }

  static List<CatalogCourse> getLawUGCourses() {
    return [
      CatalogCourse(
        id: 'llb',
        name: 'LLB',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Laws (3 Year)',
        curricula: [
          CatalogCurriculum(
            id: 'curr_llb_2025',
            courseId: 'llb',
            versionCode: currentVersion,
            name: 'LLB Curriculum ($currentVersion)',
            structure: List.generate(6, (i) => _buildLawSemester('llb', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'ba_llb',
        name: 'BA LLB',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Integrated BA LLB (5 Year)',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ba_llb_2025',
            courseId: 'ba_llb',
            versionCode: currentVersion,
            name: 'BA LLB Curriculum ($currentVersion)',
            structure: List.generate(10, (i) => _buildLawSemester('ba_llb', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'bba_llb',
        name: 'BBA LLB',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Integrated BBA LLB (5 Year)',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bba_llb_2025',
            courseId: 'bba_llb',
            versionCode: currentVersion,
            name: 'BBA LLB Curriculum ($currentVersion)',
            structure: List.generate(10, (i) => _buildLawSemester('bba_llb', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'bcom_llb',
        name: 'B.Com LLB',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Integrated B.Com LLB (5 Year)',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bcom_llb_2025',
            courseId: 'bcom_llb',
            versionCode: currentVersion,
            name: 'B.Com LLB Curriculum ($currentVersion)',
            structure: List.generate(10, (i) => _buildLawSemester('bcom_llb', i + 1)),
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildLawSemester(String program, int sem) {
    final prefix = '${program}_sem$sem';
    return CatalogNode(
      id: 'node_${program}_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        if (sem == 1) ...[
          CatalogSubject(id: '${prefix}_const', name: 'Constitutional Law', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: '${prefix}_legal', name: 'Legal Methods', type: SubjectRequirementType.compulsory),
        ] else ...[
          CatalogSubject(id: '${prefix}_core', name: 'Law Core Subject', type: SubjectRequirementType.compulsory),
        ],
      ],
    );
  }

  static List<CatalogCourse> getHealthcareUGCourses() {
    return [
      CatalogCourse(
        id: 'mbbs',
        name: 'MBBS',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Medicine, Bachelor of Surgery',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mbbs_2025',
            courseId: 'mbbs',
            versionCode: currentVersion,
            name: 'MBBS Curriculum ($currentVersion)',
            structure: List.generate(9, (i) => _buildMedicalSemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'bds',
        name: 'BDS',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Dental Surgery',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bds_2025',
            courseId: 'bds',
            versionCode: currentVersion,
            name: 'BDS Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildDentalSemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'b_pharm',
        name: 'B.Pharm',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Pharmacy',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bpharm_2025',
            courseId: 'b_pharm',
            versionCode: currentVersion,
            name: 'B.Pharm Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildPharmacySemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'bpt',
        name: 'BPT',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Physiotherapy',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bpt_2025',
            courseId: 'bpt',
            versionCode: currentVersion,
            name: 'BPT Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildPhysioSemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'bsc_nursing',
        name: 'B.Sc Nursing',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Science in Nursing',
        curricula: [
          CatalogCurriculum(
            id: 'curr_nursing_2025',
            courseId: 'bsc_nursing',
            versionCode: currentVersion,
            name: 'B.Sc Nursing Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildNursingSemester(i + 1)),
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildMedicalSemester(int sem) {
    return CatalogNode(
      id: 'node_mbbs_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        if (sem == 1) ...[
          CatalogSubject(id: 'mbbs_s${sem}_anatomy', name: 'Anatomy', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: 'mbbs_s${sem}_physio', name: 'Physiology', type: SubjectRequirementType.compulsory),
          CatalogSubject(id: 'mbbs_s${sem}_biochem', name: 'Biochemistry', type: SubjectRequirementType.compulsory),
        ] else ...[
          CatalogSubject(id: 'mbbs_s${sem}_core', name: 'Medical Core Subject', type: SubjectRequirementType.compulsory),
        ],
      ],
    );
  }

  static CatalogNode _buildDentalSemester(int sem) {
    return CatalogNode(
      id: 'node_bds_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'bds_s${sem}_core', name: 'Dental Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static CatalogNode _buildPharmacySemester(int sem) {
    return CatalogNode(
      id: 'node_bpharm_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'bpharm_s${sem}_core', name: 'Pharmacy Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static CatalogNode _buildPhysioSemester(int sem) {
    return CatalogNode(
      id: 'node_bpt_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'bpt_s${sem}_core', name: 'Physiotherapy Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static CatalogNode _buildNursingSemester(int sem) {
    return CatalogNode(
      id: 'node_nursing_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'nursing_s${sem}_core', name: 'Nursing Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static List<CatalogCourse> getDesignArchitectureUGCourses() {
    return [
      CatalogCourse(
        id: 'b_des',
        name: 'B.Des',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Design',
        curricula: [
          CatalogCurriculum(
            id: 'curr_bdes_2025',
            courseId: 'b_des',
            versionCode: currentVersion,
            name: 'B.Des Curriculum ($currentVersion)',
            structure: List.generate(8, (i) => _buildDesignSemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'b_arch',
        name: 'B.Arch',
        category: CourseCategory.undergraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Bachelor of Architecture',
        curricula: [
          CatalogCurriculum(
            id: 'curr_barch_2025',
            courseId: 'b_arch',
            versionCode: currentVersion,
            name: 'B.Arch Curriculum ($currentVersion)',
            structure: List.generate(10, (i) => _buildArchitectureSemester(i + 1)),
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildDesignSemester(int sem) {
    return CatalogNode(
      id: 'node_bdes_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'bdes_s${sem}_core', name: 'Design Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static CatalogNode _buildArchitectureSemester(int sem) {
    return CatalogNode(
      id: 'node_barch_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'barch_s${sem}_core', name: 'Architecture Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static List<CatalogCourse> getCommercePGCourses() {
    return [
      CatalogCourse(
        id: 'mcom',
        name: 'M.Com',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Commerce',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mcom_2025',
            courseId: 'mcom',
            versionCode: currentVersion,
            name: 'M.Com Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildMComSemester(i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'mba',
        name: 'MBA',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Business Administration',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mba_2025',
            courseId: 'mba',
            versionCode: currentVersion,
            name: 'MBA Curriculum ($currentVersion)',
            structure: [
              CatalogNode(
                id: 'node_mba_structure',
                name: 'MBA Structure',
                type: CatalogNodeType.level,
                children: [
                  _buildMBASpecialization('finance'),
                  _buildMBASpecialization('marketing'),
                  _buildMBASpecialization('hr'),
                  _buildMBASpecialization('operations'),
                  _buildMBASpecialization('analytics'),
                  _buildMBASpecialization('international'),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildMComSemester(int sem) {
    return CatalogNode(
      id: 'node_mcom_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: 'mcom_s${sem}_core', name: 'Commerce Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }

  static CatalogNode _buildMBASpecialization(String spec) {
    final labels = {
      'finance': 'Finance',
      'marketing': 'Marketing',
      'hr': 'Human Resources',
      'operations': 'Operations',
      'analytics': 'Business Analytics',
      'international': 'International Business',
    };

    return CatalogNode(
      id: 'node_mba_$spec',
      name: 'MBA ${labels[spec]}',
      type: CatalogNodeType.specialization,
      children: List.generate(
        4,
        (i) {
          final sem = i + 1;
          return CatalogNode(
            id: 'node_mba_${spec}_sem_$sem',
            name: 'Semester $sem',
            type: CatalogNodeType.semester,
            sortOrder: sem,
            subjects: [
              CatalogSubject(
                id: 'mba_${spec}_s${sem}_core',
                name: '${labels[spec]} Core Subject',
                type: SubjectRequirementType.compulsory,
              ),
            ],
          );
        },
      ),
    );
  }

  static List<CatalogCourse> getArtsPGCourses() {
    return [
      CatalogCourse(
        id: 'ma',
        name: 'MA',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Arts',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ma_2025',
            courseId: 'ma',
            versionCode: currentVersion,
            name: 'MA Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('ma', i + 1)),
          ),
        ],
      ),
    ];
  }

  static List<CatalogCourse> getSciencePGCourses() {
    return [
      CatalogCourse(
        id: 'msc',
        name: 'M.Sc',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_msc_2025',
            courseId: 'msc',
            versionCode: currentVersion,
            name: 'M.Sc Curriculum ($currentVersion)',
            structure: [
              CatalogNode(
                id: 'node_msc_structure',
                name: 'M.Sc Structure',
                type: CatalogNodeType.level,
                children: [
                  _buildMScSpecialization('physics'),
                  _buildMScSpecialization('chemistry'),
                  _buildMScSpecialization('mathematics'),
                  _buildMScSpecialization('biology'),
                ],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildMScSpecialization(String spec) {
    final labels = {
      'physics': 'Physics',
      'chemistry': 'Chemistry',
      'mathematics': 'Mathematics',
      'biology': 'Biology',
    };

    return CatalogNode(
      id: 'node_msc_$spec',
      name: 'M.Sc ${labels[spec]}',
      type: CatalogNodeType.specialization,
      children: List.generate(4, (i) => _buildGenericPGSemester('msc_$spec', i + 1)),
    );
  }

  static List<CatalogCourse> getComputerITPGCourses() {
    return [
      CatalogCourse(
        id: 'mca',
        name: 'MCA',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Computer Applications',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mca_2025',
            courseId: 'mca',
            versionCode: currentVersion,
            name: 'MCA Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('mca', i + 1)),
          ),
        ],
      ),
    ];
  }

  static List<CatalogCourse> getEngineeringPGCourses() {
    return [
      CatalogCourse(
        id: 'mtech_cse',
        name: 'M.Tech Computer Science',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Technology in Computer Science & Engineering',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mtech_cse_2025',
            courseId: 'mtech_cse',
            versionCode: currentVersion,
            name: 'M.Tech CSE Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('mtech_cse', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'mtech_aiml',
        name: 'M.Tech AI & ML',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Technology in Artificial Intelligence & Machine Learning',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mtech_aiml_2025',
            courseId: 'mtech_aiml',
            versionCode: currentVersion,
            name: 'M.Tech AI-ML Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('mtech_aiml', i + 1)),
          ),
        ],
      ),
      CatalogCourse(
        id: 'mtech_ds',
        name: 'M.Tech Data Science',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Technology in Data Science',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mtech_ds_2025',
            courseId: 'mtech_ds',
            versionCode: currentVersion,
            name: 'M.Tech Data Science Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('mtech_ds', i + 1)),
          ),
        ],
      ),
    ];
  }

  static List<CatalogCourse> getLawPGCourses() {
    return [
      CatalogCourse(
        id: 'llm',
        name: 'LLM',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Laws',
        curricula: [
          CatalogCurriculum(
            id: 'curr_llm_2025',
            courseId: 'llm',
            versionCode: currentVersion,
            name: 'LLM Curriculum ($currentVersion)',
            structure: List.generate(2, (i) => _buildGenericPGSemester('llm', i + 1)),
          ),
        ],
      ),
    ];
  }

  static List<CatalogCourse> getDesignPGCourses() {
    return [
      CatalogCourse(
        id: 'm_des',
        name: 'M.Des',
        category: CourseCategory.postgraduate,
        authority: 'Generic',
        catalogVersion: currentVersion,
        description: 'Master of Design',
        curricula: [
          CatalogCurriculum(
            id: 'curr_mdes_2025',
            courseId: 'm_des',
            versionCode: currentVersion,
            name: 'M.Des Curriculum ($currentVersion)',
            structure: List.generate(4, (i) => _buildGenericPGSemester('mdes', i + 1)),
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildGenericPGSemester(String prefix, int sem) {
    return CatalogNode(
      id: 'node_${prefix}_sem_$sem',
      name: 'Semester $sem',
      type: CatalogNodeType.semester,
      sortOrder: sem,
      subjects: [
        CatalogSubject(id: '${prefix}_s${sem}_core', name: 'Core Subject', type: SubjectRequirementType.compulsory),
      ],
    );
  }
}
