import '../models/catalog/catalog_course.dart';
import '../models/catalog/catalog_curriculum.dart';
import '../models/catalog/catalog_node.dart';
import '../models/catalog/catalog_subject.dart';
import '../models/catalog/course_category.dart';

abstract final class ProfessionalCatalogData {
  static const String currentVersion = '2025-2026';

  static List<CatalogCourse> getAllProfessionalCourses() {
    return [
      ...getCAcourses(),
      ...getCSCourses(),
      ...getCMACourses(),
      ...getACCACourses(),
      ...getCFACourses(),
      ...getFRMCourses(),
      ...getActuarialCourses(),
    ];
  }

  static List<CatalogCourse> getCAcourses() {
    return [
      CatalogCourse(
        id: 'ca_foundation',
        name: 'CA Foundation',
        category: CourseCategory.professional,
        authority: 'ICAI',
        catalogVersion: currentVersion,
        description: 'Chartered Accountancy Foundation Course',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ca_foundation_2025',
            courseId: 'ca_foundation',
            versionCode: currentVersion,
            name: 'CA Foundation Curriculum ($currentVersion)',
            structure: [_buildCAFoundationStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ca_intermediate',
        name: 'CA Intermediate',
        category: CourseCategory.professional,
        authority: 'ICAI',
        catalogVersion: currentVersion,
        description: 'Chartered Accountancy Intermediate Course',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ca_intermediate_2025',
            courseId: 'ca_intermediate',
            versionCode: currentVersion,
            name: 'CA Intermediate Curriculum ($currentVersion)',
            structure: [_buildCAIntermediateStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'ca_final',
        name: 'CA Final',
        category: CourseCategory.professional,
        authority: 'ICAI',
        catalogVersion: currentVersion,
        description: 'Chartered Accountancy Final Course',
        curricula: [
          CatalogCurriculum(
            id: 'curr_ca_final_2025',
            courseId: 'ca_final',
            versionCode: currentVersion,
            name: 'CA Final Curriculum ($currentVersion)',
            structure: [_buildCAFinalStructure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildCAFoundationStructure() {
    return CatalogNode(
      id: 'node_ca_foundation',
      name: 'Foundation Level',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'ca_f_accounting',
          name: 'Accounting',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'ca_f_business',
          name: 'Business Laws',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'ca_f_qa',
          name: 'Quantitative Aptitude',
          description: 'Business Mathematics, Logical Reasoning, Statistics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'ca_f_eco',
          name: 'Business Economics',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildCAIntermediateStructure() {
    return CatalogNode(
      id: 'node_ca_intermediate',
      name: 'Intermediate Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_ca_intermediate_group1',
          name: 'Group I',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'ca_int_g1_accounting',
              name: 'Accounting & Finance',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g1_audit',
              name: 'Audit & Assurance',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g1_company_law',
              name: 'Company Law',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g1_cost_mgmt',
              name: 'Cost & Management Accounting',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_ca_intermediate_group2',
          name: 'Group II',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'ca_int_g2_advanced_audit',
              name: 'Advanced Audit & Professional Ethics',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g2_indirect_tax',
              name: 'Indirect Taxation',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g2_direct_tax',
              name: 'Direct Taxation',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_int_g2_financial_reporting',
              name: 'Financial Reporting Standards',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildCAFinalStructure() {
    return CatalogNode(
      id: 'node_ca_final',
      name: 'Final Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_ca_final_group1',
          name: 'Group I',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'ca_final_g1_audit',
              name: 'Audit & Assurance',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_final_g1_advanced_tax',
              name: 'Advanced Taxation',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_final_g1_adv_accounting',
              name: 'Advanced Accounting',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_ca_final_group2',
          name: 'Group II',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'ca_final_g2_fra',
              name: 'Financial Reporting & Analysis',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_final_g2_caf',
              name: 'Corporate Affairs & Finance',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'ca_final_g2_itsm',
              name: 'Information Systems & Technology',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getCSCourses() {
    return [
      CatalogCourse(
        id: 'cs_cseet',
        name: 'CS CSEET',
        category: CourseCategory.professional,
        authority: 'ICSI',
        catalogVersion: currentVersion,
        description: 'Company Secretary Executive Entrance Test',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cs_cseet_2025',
            courseId: 'cs_cseet',
            versionCode: currentVersion,
            name: 'CS CSEET Curriculum ($currentVersion)',
            structure: [_buildCSCseetStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cs_executive',
        name: 'CS Executive',
        category: CourseCategory.professional,
        authority: 'ICSI',
        catalogVersion: currentVersion,
        description: 'Company Secretary Executive Program',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cs_executive_2025',
            courseId: 'cs_executive',
            versionCode: currentVersion,
            name: 'CS Executive Curriculum ($currentVersion)',
            structure: [_buildCSExecutiveStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cs_professional',
        name: 'CS Professional',
        category: CourseCategory.professional,
        authority: 'ICSI',
        catalogVersion: currentVersion,
        description: 'Company Secretary Professional Program',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cs_professional_2025',
            courseId: 'cs_professional',
            versionCode: currentVersion,
            name: 'CS Professional Curriculum ($currentVersion)',
            structure: [_buildCSProfessionalStructure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildCSCseetStructure() {
    return CatalogNode(
      id: 'node_cs_cseet',
      name: 'CSEET Level',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'cs_cseet_admin',
          name: 'Corporate Administration & Secretarial Practice',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cs_cseet_business',
          name: 'Business Environment & Concepts',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cs_cseet_law',
          name: 'Legal Environment & Ethics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cs_cseet_accounts',
          name: 'Accounting & Finance',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildCSExecutiveStructure() {
    return CatalogNode(
      id: 'node_cs_executive',
      name: 'Executive Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_cs_exec_module1',
          name: 'Module 1',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'cs_exec_m1_cos',
              name: 'Company Law & Secretarial Practice',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'cs_exec_m1_admin',
              name: 'Corporate Administration',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_cs_exec_module2',
          name: 'Module 2',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'cs_exec_m2_tax',
              name: 'Taxation',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'cs_exec_m2_accounting',
              name: 'Accounting & Finance',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildCSProfessionalStructure() {
    return CatalogNode(
      id: 'node_cs_professional',
      name: 'Professional Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_cs_prof_module1',
          name: 'Module 1',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'cs_prof_m1_governance',
              name: 'Corporate Governance & Ethics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'cs_prof_m1_secretarial',
              name: 'Secretarial Audit & Compliance',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_cs_prof_module2',
          name: 'Module 2',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'cs_prof_m2_labour',
              name: 'Labour Laws & Industrial Relations',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'cs_prof_m2_drafting',
              name: 'Drafting & Conveyancing',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getCMACourses() {
    return [
      CatalogCourse(
        id: 'cma_foundation',
        name: 'CMA Foundation',
        category: CourseCategory.professional,
        authority: 'ICMAI',
        catalogVersion: currentVersion,
        description: 'Cost & Management Accountancy Foundation',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cma_foundation_2025',
            courseId: 'cma_foundation',
            versionCode: currentVersion,
            name: 'CMA Foundation Curriculum ($currentVersion)',
            structure: [_buildCMAFoundationStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cma_intermediate',
        name: 'CMA Intermediate',
        category: CourseCategory.professional,
        authority: 'ICMAI',
        catalogVersion: currentVersion,
        description: 'Cost & Management Accountancy Intermediate',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cma_intermediate_2025',
            courseId: 'cma_intermediate',
            versionCode: currentVersion,
            name: 'CMA Intermediate Curriculum ($currentVersion)',
            structure: [_buildCMAIntermediateStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cma_final',
        name: 'CMA Final',
        category: CourseCategory.professional,
        authority: 'ICMAI',
        catalogVersion: currentVersion,
        description: 'Cost & Management Accountancy Final',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cma_final_2025',
            courseId: 'cma_final',
            versionCode: currentVersion,
            name: 'CMA Final Curriculum ($currentVersion)',
            structure: [_buildCMAFinalStructure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildCMAFoundationStructure() {
    return CatalogNode(
      id: 'node_cma_foundation',
      name: 'Foundation Level',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'cma_f_accounting',
          name: 'Fundamentals of Accounting & Finance',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cma_f_cost',
          name: 'Cost Accounting',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cma_f_mgmt',
          name: 'Management Accounting',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildCMAIntermediateStructure() {
    return CatalogNode(
      id: 'node_cma_intermediate',
      name: 'Intermediate Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_cma_int_group1',
          name: 'Group I',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'cma_int_g1_accounting',
              name: 'Cost Accounting',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'cma_int_g1_mgmt',
              name: 'Cost & Management Accounting',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_cma_int_group2',
          name: 'Group II',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'cma_int_g2_advanced',
              name: 'Advanced Cost Accounting',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'cma_int_g2_systems',
              name: 'Financial & Management Systems',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildCMAFinalStructure() {
    return CatalogNode(
      id: 'node_cma_final',
      name: 'Final Level',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_cma_final_group1',
          name: 'Group I',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'cma_final_g1_strategic',
              name: 'Strategic Cost Management',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'cma_final_g1_performance',
              name: 'Performance Management',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_cma_final_group2',
          name: 'Group II',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'cma_final_g2_treasury',
              name: 'Treasury Management & Financial Analysis',
              type: SubjectRequirementType.groupSpecific,
            ),
            CatalogSubject(
              id: 'cma_final_g2_strategic',
              name: 'Strategic Financial Management',
              type: SubjectRequirementType.groupSpecific,
            ),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getACCACourses() {
    return [
      CatalogCourse(
        id: 'acca_applied_knowledge',
        name: 'ACCA Applied Knowledge',
        category: CourseCategory.professional,
        authority: 'ACCA',
        catalogVersion: currentVersion,
        description: 'ACCA Applied Knowledge Level',
        curricula: [
          CatalogCurriculum(
            id: 'curr_acca_ak_2025',
            courseId: 'acca_applied_knowledge',
            versionCode: currentVersion,
            name: 'ACCA Applied Knowledge Curriculum ($currentVersion)',
            structure: [_buildACCAAppliedKnowledgeStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'acca_applied_skills',
        name: 'ACCA Applied Skills',
        category: CourseCategory.professional,
        authority: 'ACCA',
        catalogVersion: currentVersion,
        description: 'ACCA Applied Skills Level',
        curricula: [
          CatalogCurriculum(
            id: 'curr_acca_as_2025',
            courseId: 'acca_applied_skills',
            versionCode: currentVersion,
            name: 'ACCA Applied Skills Curriculum ($currentVersion)',
            structure: [_buildACCAAppliedSkillsStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'acca_strategic_professional',
        name: 'ACCA Strategic Professional',
        category: CourseCategory.professional,
        authority: 'ACCA',
        catalogVersion: currentVersion,
        description: 'ACCA Strategic Professional Level',
        curricula: [
          CatalogCurriculum(
            id: 'curr_acca_sp_2025',
            courseId: 'acca_strategic_professional',
            versionCode: currentVersion,
            name: 'ACCA Strategic Professional Curriculum ($currentVersion)',
            structure: [_buildACCAStrategicProfessionalStructure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildACCAAppliedKnowledgeStructure() {
    return CatalogNode(
      id: 'node_acca_ak',
      name: 'Applied Knowledge',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'acca_ak_accounting',
          name: 'Accounting & Finance',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_ak_business',
          name: 'Business & Technology',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_ak_business_law',
          name: 'Business Law',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_ak_fundamentals',
          name: 'Fundamentals of Audit',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildACCAAppliedSkillsStructure() {
    return CatalogNode(
      id: 'node_acca_as',
      name: 'Applied Skills',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'acca_as_financial_accounting',
          name: 'Financial Accounting & Reporting',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_as_management_accounting',
          name: 'Management Accounting',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_as_audit',
          name: 'Audit & Assurance',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_as_taxation',
          name: 'Taxation',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'acca_as_financial_mgt',
          name: 'Financial Management',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildACCAStrategicProfessionalStructure() {
    return CatalogNode(
      id: 'node_acca_sp',
      name: 'Strategic Professional',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_acca_sp_compulsory',
          name: 'Compulsory Papers',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'acca_sp_sfp',
              name: 'Strategic Business Leader',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'acca_sp_aaa',
              name: 'Advanced Audit & Assurance',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_acca_sp_optional',
          name: 'Optional Papers',
          type: CatalogNodeType.group,
          subjects: [
            CatalogSubject(
              id: 'acca_sp_afm',
              name: 'Advanced Financial Management',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: 'acca_sp_atx',
              name: 'Advanced Taxation',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: 'acca_sp_aat',
              name: 'Advanced Audit & Assurance (Alt)',
              type: SubjectRequirementType.optional,
            ),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getCFACourses() {
    return [
      CatalogCourse(
        id: 'cfa_level1',
        name: 'CFA Level I',
        category: CourseCategory.professional,
        authority: 'CFA Institute',
        catalogVersion: currentVersion,
        description: 'Chartered Financial Analyst Level I',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cfa_l1_2025',
            courseId: 'cfa_level1',
            versionCode: currentVersion,
            name: 'CFA Level I Curriculum ($currentVersion)',
            structure: [_buildCFALevel1Structure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cfa_level2',
        name: 'CFA Level II',
        category: CourseCategory.professional,
        authority: 'CFA Institute',
        catalogVersion: currentVersion,
        description: 'Chartered Financial Analyst Level II',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cfa_l2_2025',
            courseId: 'cfa_level2',
            versionCode: currentVersion,
            name: 'CFA Level II Curriculum ($currentVersion)',
            structure: [_buildCFALevel2Structure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'cfa_level3',
        name: 'CFA Level III',
        category: CourseCategory.professional,
        authority: 'CFA Institute',
        catalogVersion: currentVersion,
        description: 'Chartered Financial Analyst Level III',
        curricula: [
          CatalogCurriculum(
            id: 'curr_cfa_l3_2025',
            courseId: 'cfa_level3',
            versionCode: currentVersion,
            name: 'CFA Level III Curriculum ($currentVersion)',
            structure: [_buildCFALevel3Structure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildCFALevel1Structure() {
    return CatalogNode(
      id: 'node_cfa_level1',
      name: 'Level I',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'cfa_l1_ethics',
          name: 'Ethics & Professional Standards',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_quantitative',
          name: 'Quantitative Methods',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_economics',
          name: 'Economics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_financial_reporting',
          name: 'Financial Reporting & Analysis',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_corporate_finance',
          name: 'Corporate Finance',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_equity',
          name: 'Equity Investments',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_fixed_income',
          name: 'Fixed Income',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_derivatives',
          name: 'Derivatives',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_alternative',
          name: 'Alternative Investments',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l1_portfolio',
          name: 'Portfolio Management',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildCFALevel2Structure() {
    return CatalogNode(
      id: 'node_cfa_level2',
      name: 'Level II',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'cfa_l2_ethics',
          name: 'Ethics & Professional Standards',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_quantitative',
          name: 'Quantitative Methods',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_economics',
          name: 'Economics',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_financial_reporting',
          name: 'Financial Reporting & Analysis',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_corporate_finance',
          name: 'Corporate Finance',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_equity',
          name: 'Equity Investments',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_fixed_income',
          name: 'Fixed Income',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_derivatives',
          name: 'Derivatives',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_alternative',
          name: 'Alternative Investments',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l2_portfolio',
          name: 'Portfolio Management',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static CatalogNode _buildCFALevel3Structure() {
    return CatalogNode(
      id: 'node_cfa_level3',
      name: 'Level III',
      type: CatalogNodeType.level,
      subjects: [
        CatalogSubject(
          id: 'cfa_l3_ethics',
          name: 'Ethics & Professional Standards',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l3_wealth',
          name: 'Wealth Planning',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l3_asset_allocation',
          name: 'Asset Allocation',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l3_fixed_income',
          name: 'Fixed Income Portfolio Management',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l3_equity',
          name: 'Equity Portfolio Management',
          type: SubjectRequirementType.compulsory,
        ),
        CatalogSubject(
          id: 'cfa_l3_derivatives',
          name: 'Derivatives & Currency Management',
          type: SubjectRequirementType.compulsory,
        ),
      ],
    );
  }

  static List<CatalogCourse> getFRMCourses() {
    return [
      CatalogCourse(
        id: 'frm_part1',
        name: 'FRM Part I',
        category: CourseCategory.professional,
        authority: 'GARP',
        catalogVersion: currentVersion,
        description: 'Financial Risk Manager Part I',
        curricula: [
          CatalogCurriculum(
            id: 'curr_frm_p1_2025',
            courseId: 'frm_part1',
            versionCode: currentVersion,
            name: 'FRM Part I Curriculum ($currentVersion)',
            structure: [_buildFRMPart1Structure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'frm_part2',
        name: 'FRM Part II',
        category: CourseCategory.professional,
        authority: 'GARP',
        catalogVersion: currentVersion,
        description: 'Financial Risk Manager Part II',
        curricula: [
          CatalogCurriculum(
            id: 'curr_frm_p2_2025',
            courseId: 'frm_part2',
            versionCode: currentVersion,
            name: 'FRM Part II Curriculum ($currentVersion)',
            structure: [_buildFRMPart2Structure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildFRMPart1Structure() {
    return CatalogNode(
      id: 'node_frm_part1',
      name: 'Part I',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_frm_p1_fundamentals',
          name: 'Fundamentals of Risk Management',
          type: CatalogNodeType.paperGroup,
          subjects: [
            CatalogSubject(
              id: 'frm_p1_governance',
              name: 'Risk Management & Governance',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'frm_p1_quantitative',
              name: 'Quantitative Analysis',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_frm_p1_valuation',
          name: 'Valuation & Risk Models',
          type: CatalogNodeType.paperGroup,
          subjects: [
            CatalogSubject(
              id: 'frm_p1_valuation',
              name: 'Valuation & Risk Models',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'frm_p1_market_risk',
              name: 'Market Risk',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildFRMPart2Structure() {
    return CatalogNode(
      id: 'node_frm_part2',
      name: 'Part II',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_frm_p2_credit',
          name: 'Credit Risk',
          type: CatalogNodeType.paperGroup,
          subjects: [
            CatalogSubject(
              id: 'frm_p2_credit',
              name: 'Credit Risk Measurement & Management',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_frm_p2_operational',
          name: 'Operational Risk',
          type: CatalogNodeType.paperGroup,
          subjects: [
            CatalogSubject(
              id: 'frm_p2_operational',
              name: 'Operational Risk & Resilience',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_frm_p2_integrated',
          name: 'Integrated Risk Management',
          type: CatalogNodeType.paperGroup,
          subjects: [
            CatalogSubject(
              id: 'frm_p2_integrated',
              name: 'Integrated Risk Management',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
      ],
    );
  }

  static List<CatalogCourse> getActuarialCourses() {
    return [
      CatalogCourse(
        id: 'actuarial_iam',
        name: 'Actuarial (Institute & Faculty of Actuaries)',
        category: CourseCategory.professional,
        authority: 'Institute & Faculty of Actuaries',
        catalogVersion: currentVersion,
        description: 'Actuarial Sciences - IFoA',
        curricula: [
          CatalogCurriculum(
            id: 'curr_iam_2025',
            courseId: 'actuarial_iam',
            versionCode: currentVersion,
            name: 'IFoA Actuarial Curriculum ($currentVersion)',
            structure: [_buildActuarialIAMStructure()],
          ),
        ],
      ),
      CatalogCourse(
        id: 'actuarial_soa',
        name: 'Actuarial (Society of Actuaries)',
        category: CourseCategory.professional,
        authority: 'Society of Actuaries',
        catalogVersion: currentVersion,
        description: 'Actuarial Sciences - SOA',
        curricula: [
          CatalogCurriculum(
            id: 'curr_soa_2025',
            courseId: 'actuarial_soa',
            versionCode: currentVersion,
            name: 'SOA Actuarial Curriculum ($currentVersion)',
            structure: [_buildActuarialSOAStructure()],
          ),
        ],
      ),
    ];
  }

  static CatalogNode _buildActuarialIAMStructure() {
    return CatalogNode(
      id: 'node_iam_actuarial',
      name: 'IFoA Actuarial',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_iam_core',
          name: 'Core Principles',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'iam_cm1',
              name: 'Actuarial Mathematics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'iam_cb1',
              name: 'Business & Finance',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'iam_cs1',
              name: 'Actuarial Statistics',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_iam_specialist',
          name: 'Specialist Principles',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'iam_sp1',
              name: 'Life Insurance',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: 'iam_sp2',
              name: 'General Insurance',
              type: SubjectRequirementType.optional,
            ),
            CatalogSubject(
              id: 'iam_sp3',
              name: 'Pensions',
              type: SubjectRequirementType.optional,
            ),
          ],
        ),
      ],
    );
  }

  static CatalogNode _buildActuarialSOAStructure() {
    return CatalogNode(
      id: 'node_soa_actuarial',
      name: 'SOA Actuarial',
      type: CatalogNodeType.level,
      children: [
        CatalogNode(
          id: 'node_soa_foundational',
          name: 'Foundational Exams',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'soa_p',
              name: 'Probability',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'soa_fm',
              name: 'Financial Mathematics',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'soa_ifm',
              name: 'Investment & Financial Markets',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
        CatalogNode(
          id: 'node_soa_intermediate',
          name: 'Intermediate Exams',
          type: CatalogNodeType.module,
          subjects: [
            CatalogSubject(
              id: 'soa_lc',
              name: 'Life Contingencies',
              type: SubjectRequirementType.compulsory,
            ),
            CatalogSubject(
              id: 'soa_ltam',
              name: 'Life & Annuities',
              type: SubjectRequirementType.compulsory,
            ),
          ],
        ),
      ],
    );
  }
}
