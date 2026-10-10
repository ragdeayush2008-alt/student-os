import '../../models/catalog/catalog_family.dart';
import '../../models/catalog/catalog_level.dart';
import '../../models/catalog/catalog_node.dart';
import '../../models/catalog/catalog_paper.dart';
import '../../models/catalog/catalog_program.dart';
import '../../models/catalog/catalog_subject.dart';

abstract final class EngineeringCatalogData {
  static const categoryId = 'engineering_technology';

  static List<CatalogFamily> getFamilies() => [
    _jeeFamily,
    _gateFamily,
    _mhtCetFamily,
    _stateEnggFamily,
    _btechFamily,
  ];

  static List<CatalogProgram> getPrograms() => [
    ..._getJEEPrograms(),
    ..._getGATEPrograms(),
    ..._getMHTCETPrograms(),
    ..._getStateEnggPrograms(),
    ..._getBTechPrograms(),
  ];

  // ─── JEE ─────────────────────────────────────────────────────────────

  static const _jeeFamily = CatalogFamily(
    id: 'jee',
    categoryId: categoryId,
    title: 'Joint Entrance Examination',
    shortTitle: 'JEE',
    description: 'JEE Main and JEE Advanced for IITs, NITs & IIITs',
    aliases: ['IIT JEE', 'JEE Main', 'JEE Advanced', 'NTA JEE'],
    isPopular: true,
    programIds: ['jee_main', 'jee_advanced'],
  );

  static List<CatalogProgram> _getJEEPrograms() => [
    CatalogProgram(
      id: 'jee_main',
      familyId: 'jee',
      categoryId: categoryId,
      title: 'JEE Main',
      authority: 'NTA',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'jee_m_p1',
          programId: 'jee_main',
          title: 'Paper 1 (B.E. / B.Tech)',
          year: '2026',
          papers: [
            CatalogPaper(id: 'jee_m_phy', programId: 'jee_main', levelId: 'jee_m_p1', title: 'Physics', order: 1),
            CatalogPaper(id: 'jee_m_chem', programId: 'jee_main', levelId: 'jee_m_p1', title: 'Chemistry', order: 2),
            CatalogPaper(id: 'jee_m_math', programId: 'jee_main', levelId: 'jee_m_p1', title: 'Mathematics', order: 3),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'jee_advanced',
      familyId: 'jee',
      categoryId: categoryId,
      title: 'JEE Advanced',
      authority: 'IITs',
      defaultYear: '2026',
      isPopular: true,
      levels: [
        CatalogLevel(
          id: 'jee_adv_level',
          programId: 'jee_advanced',
          title: 'Paper 1 & Paper 2',
          year: '2026',
          papers: [
            CatalogPaper(id: 'jee_a_phy', programId: 'jee_advanced', levelId: 'jee_adv_level', title: 'Physics', order: 1),
            CatalogPaper(id: 'jee_a_chem', programId: 'jee_advanced', levelId: 'jee_adv_level', title: 'Chemistry', order: 2),
            CatalogPaper(id: 'jee_a_math', programId: 'jee_advanced', levelId: 'jee_adv_level', title: 'Mathematics', order: 3),
          ],
        ),
      ],
    ),
  ];

  // ─── GATE ────────────────────────────────────────────────────────────

  static const _gateFamily = CatalogFamily(
    id: 'gate',
    categoryId: categoryId,
    title: 'Graduate Aptitude Test in Engineering',
    shortTitle: 'GATE',
    description: 'GATE 2026 official disciplines and test papers',
    aliases: ['GATE 2026', 'M.Tech Entrance', 'PSU Recruitment'],
    isPopular: true,
    programIds: ['gate_2026'],
  );

  static List<CatalogProgram> _getGATEPrograms() {
    final gateDisciplines = [
      ('cs_it', 'Computer Science and Information Technology (CS)', 'Engineering Mathematics, Digital Logic, Computer Organization, Programming & Data Structures, Algorithms, Theory of Computation, Compiler Design, OS, DBMS, Computer Networks'),
      ('da', 'Data Science & Artificial Intelligence (DA)', 'Probability & Statistics, Linear Algebra, Calculus, Programming & Data Structures, DBMS, Machine Learning, AI'),
      ('ec', 'Electronics & Communication Engineering (EC)', 'Engineering Mathematics, Networks, Signals, Electronic Devices, Analog Circuits, Digital Circuits, Control Systems, Communications, Electromagnetics'),
      ('ee', 'Electrical Engineering (EE)', 'Engineering Mathematics, Electric Circuits, Electromagnetic Fields, Signals, Electrical Machines, Power Systems, Control Systems, Power Electronics'),
      ('me', 'Mechanical Engineering (ME)', 'Engineering Mathematics, Applied Mechanics, Strength of Materials, Theory of Machines, Fluid Mechanics, Thermodynamics, Manufacturing'),
      ('ce', 'Civil Engineering (CE)', 'Engineering Mathematics, Structural Engineering, Geotechnical Engineering, Water Resources, Environmental Engineering, Transportation'),
      ('ae', 'Aerospace Engineering (AE)', 'Engineering Mathematics, Flight Mechanics, Aerodynamics, Structures, Propulsion, Space Dynamics'),
      ('ag', 'Agricultural Engineering (AG)', 'Engineering Mathematics, Farm Machinery, Soil and Water Conservation, Processing and Food Engineering'),
      ('ar', 'Architecture and Planning (AR)', 'Architecture & Housing, Planning Process, Services & Infrastructure'),
      ('bm', 'Biomedical Engineering (BM)', 'Engineering Mathematics, Electrical Circuits, Sensors & Bio-instrumentation, Biomechanics, Medical Imaging'),
      ('bt', 'Biotechnology (BT)', 'Engineering Mathematics, Microbiology, Biochemistry, Molecular Biology, Bioprocess Engineering'),
      ('ch', 'Chemical Engineering (CH)', 'Engineering Mathematics, Process Calculations, Thermodynamics, Fluid Mechanics, Heat Transfer, Mass Transfer, Chemical Reaction Engineering'),
      ('es', 'Environmental Science and Engineering (ES)', 'Mathematics Foundation, Environmental Chemistry, Microbiology, Water Resources, Air & Noise Pollution'),
      ('ge', 'Geomatics Engineering (GE)', 'Surveying, Remote Sensing, GNSS, GIS'),
      ('in', 'Instrumentation Engineering (IN)', 'Engineering Mathematics, Electricity and Magnetism, Electrical Circuits, Signals, Control Systems, Analog & Digital Electronics, Sensors'),
      ('ma', 'Mathematics (MA)', 'Linear Algebra, Complex Analysis, Real Analysis, Ordinary Differential Equations, Algebra, Functional Analysis, Numerical Analysis'),
      ('mt', 'Metallurgical Engineering (MT)', 'Engineering Mathematics, Thermodynamics, Extraction of Metals, Physical Metallurgy, Mechanical Metallurgy'),
      ('nm', 'Naval Architecture and Marine Engineering (NM)', 'Engineering Mathematics, Hydrostatics, Marine Hydrodynamics, Ship Structures, Ship Propulsion'),
      ('pe', 'Petroleum Engineering (PE)', 'Petroleum Exploration, Drilling Engineering, Reservoir Engineering, Production Engineering'),
      ('ph', 'Physics (PH)', 'Mathematical Physics, Classical Mechanics, Electromagnetic Theory, Quantum Mechanics, Thermodynamics, Solid State Physics, Nuclear Physics'),
    ];

    return [
      CatalogProgram(
        id: 'gate_2026',
        familyId: 'gate',
        categoryId: categoryId,
        title: 'GATE 2026',
        authority: 'IITs / IISc',
        defaultYear: '2026',
        isPopular: true,
        levels: gateDisciplines.map((d) {
          final (code, name, desc) = d;
          return CatalogLevel(
            id: 'gate_2026_$code',
            programId: 'gate_2026',
            title: name,
            code: code.toUpperCase(),
            description: desc,
            papers: [
              CatalogPaper(
                id: 'gate_2026_${code}_ga',
                programId: 'gate_2026',
                levelId: 'gate_2026_$code',
                title: 'General Aptitude (GA)',
                order: 1,
              ),
              CatalogPaper(
                id: 'gate_2026_${code}_core',
                programId: 'gate_2026',
                levelId: 'gate_2026_$code',
                title: name,
                description: desc,
                order: 2,
              ),
            ],
          );
        }).toList(),
      ),
    ];
  }

  // ─── MHT-CET ─────────────────────────────────────────────────────────

  static const _mhtCetFamily = CatalogFamily(
    id: 'mht_cet',
    categoryId: categoryId,
    title: 'Maharashtra Common Entrance Test',
    shortTitle: 'MHT-CET',
    description: 'Maharashtra CET for Engineering, Pharmacy & Technical Programs',
    aliases: ['MHT CET', 'Maharashtra CET', 'State CET Cell'],
    programIds: ['mht_cet_engg', 'mht_cet_bca_bba'],
  );

  static List<CatalogProgram> _getMHTCETPrograms() => [
    CatalogProgram(
      id: 'mht_cet_engg',
      familyId: 'mht_cet',
      categoryId: categoryId,
      title: 'MHT-CET (Engineering / Pharmacy)',
      authority: 'State CET Cell Maharashtra',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'mht_cet_pcm',
          programId: 'mht_cet_engg',
          title: 'PCM Group (Engineering)',
          papers: [
            CatalogPaper(id: 'mht_pcm_phy', programId: 'mht_cet_engg', levelId: 'mht_cet_pcm', title: 'Physics'),
            CatalogPaper(id: 'mht_pcm_chem', programId: 'mht_cet_engg', levelId: 'mht_cet_pcm', title: 'Chemistry'),
            CatalogPaper(id: 'mht_pcm_math', programId: 'mht_cet_engg', levelId: 'mht_cet_pcm', title: 'Mathematics'),
          ],
        ),
        CatalogLevel(
          id: 'mht_cet_pcb',
          programId: 'mht_cet_engg',
          title: 'PCB Group (Pharmacy / Agriculture)',
          papers: [
            CatalogPaper(id: 'mht_pcb_phy', programId: 'mht_cet_engg', levelId: 'mht_cet_pcb', title: 'Physics'),
            CatalogPaper(id: 'mht_pcb_chem', programId: 'mht_cet_engg', levelId: 'mht_cet_pcb', title: 'Chemistry'),
            CatalogPaper(id: 'mht_pcb_bio', programId: 'mht_cet_engg', levelId: 'mht_cet_pcb', title: 'Biology'),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'mht_cet_bca_bba',
      familyId: 'mht_cet',
      categoryId: categoryId,
      title: 'MAH BCA / BBA / BMS / BBM CET',
      authority: 'State CET Cell Maharashtra',
      defaultYear: '2026',
      levels: [
        CatalogLevel(
          id: 'mah_bca_cet_lvl',
          programId: 'mht_cet_bca_bba',
          title: 'General CET',
          papers: [
            CatalogPaper(id: 'mah_bca_reasoning', programId: 'mht_cet_bca_bba', levelId: 'mah_bca_cet_lvl', title: 'Reasoning (Verbal & Non-Verbal)'),
            CatalogPaper(id: 'mah_bca_english', programId: 'mht_cet_bca_bba', levelId: 'mah_bca_cet_lvl', title: 'English Language'),
            CatalogPaper(id: 'mah_bca_gk', programId: 'mht_cet_bca_bba', levelId: 'mah_bca_cet_lvl', title: 'General Knowledge & Current Affairs'),
            CatalogPaper(id: 'mah_bca_computer', programId: 'mht_cet_bca_bba', levelId: 'mah_bca_cet_lvl', title: 'Computer Concepts'),
          ],
        ),
      ],
    ),
  ];

  // ─── STATE ENGINEERING ───────────────────────────────────────────────

  static const _stateEnggFamily = CatalogFamily(
    id: 'state_engineering',
    categoryId: categoryId,
    title: 'State Engineering Entrances',
    shortTitle: 'State CETs',
    programIds: ['wbjee', 'kcet'],
  );

  static List<CatalogProgram> _getStateEnggPrograms() => [
    CatalogProgram(
      id: 'wbjee',
      familyId: 'state_engineering',
      categoryId: categoryId,
      title: 'WBJEE',
      authority: 'WBJEEB',
      levels: [
        CatalogLevel(
          id: 'wbjee_lvl',
          programId: 'wbjee',
          title: 'Engineering Stream',
          papers: [
            CatalogPaper(id: 'wbjee_math', programId: 'wbjee', levelId: 'wbjee_lvl', title: 'Mathematics'),
            CatalogPaper(id: 'wbjee_phy', programId: 'wbjee', levelId: 'wbjee_lvl', title: 'Physics'),
            CatalogPaper(id: 'wbjee_chem', programId: 'wbjee', levelId: 'wbjee_lvl', title: 'Chemistry'),
          ],
        ),
      ],
    ),
    CatalogProgram(
      id: 'kcet',
      familyId: 'state_engineering',
      categoryId: categoryId,
      title: 'KCET',
      authority: 'KEA',
      levels: [
        CatalogLevel(
          id: 'kcet_lvl',
          programId: 'kcet',
          title: 'Engineering Stream',
          papers: [
            CatalogPaper(id: 'kcet_phy', programId: 'kcet', levelId: 'kcet_lvl', title: 'Physics'),
            CatalogPaper(id: 'kcet_chem', programId: 'kcet', levelId: 'kcet_lvl', title: 'Chemistry'),
            CatalogPaper(id: 'kcet_math', programId: 'kcet', levelId: 'kcet_lvl', title: 'Mathematics'),
          ],
        ),
      ],
    ),
  ];

  // ─── B.TECH (UG ENGINEERING DEGREE) ───────────────────────────────────

  static const _btechFamily = CatalogFamily(
    id: 'btech',
    categoryId: categoryId,
    title: 'Bachelor of Technology (B.Tech)',
    shortTitle: 'B.Tech Degrees',
    programIds: ['btech_cse', 'btech_it', 'btech_aiml', 'btech_ds', 'btech_ece', 'btech_ee', 'btech_me', 'btech_civil'],
  );

  static List<CatalogProgram> _getBTechPrograms() => [
    CatalogProgram(
      id: 'btech_cse',
      familyId: 'btech',
      categoryId: categoryId,
      title: 'B.Tech Computer Science',
      authority: 'Generic',
      levels: List.generate(8, (i) {
        final sem = i + 1;
        return CatalogLevel(
          id: 'node_btech_cse_sem_$sem',
          programId: 'btech_cse',
          title: 'Semester $sem',
          type: CatalogNodeType.semester,
          order: sem,
          papers: sem == 1
              ? [
                  CatalogPaper(id: 'btech_cse_sem1_math1', programId: 'btech_cse', levelId: 'node_btech_cse_sem_1', title: 'Engineering Mathematics I'),
                  CatalogPaper(id: 'btech_cse_sem1_phy', programId: 'btech_cse', levelId: 'node_btech_cse_sem_1', title: 'Engineering Physics'),
                  CatalogPaper(id: 'btech_cse_sem1_chem', programId: 'btech_cse', levelId: 'node_btech_cse_sem_1', title: 'Engineering Chemistry'),
                ]
              : [
                  CatalogPaper(id: 'btech_cse_sem${sem}_core', programId: 'btech_cse', levelId: 'node_btech_cse_sem_$sem', title: 'Branch Core Subject'),
                  CatalogPaper(id: 'btech_cse_sem${sem}_elec', programId: 'btech_cse', levelId: 'node_btech_cse_sem_$sem', title: 'Elective', type: SubjectRequirementType.elective, isOptional: true),
                ],
        );
      }),
    ),
  ];
}
