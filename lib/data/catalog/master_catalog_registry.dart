import '../models/catalog/catalog_category.dart';
import '../models/catalog/catalog_family.dart';
import '../models/catalog/catalog_paper.dart';
import '../models/catalog/catalog_program.dart';
import 'datasets/commerce_finance_catalog_data.dart';
import 'datasets/engineering_catalog_data.dart';
import 'datasets/government_catalog_data.dart';
import 'datasets/law_catalog_data.dart';
import 'datasets/management_catalog_data.dart';
import 'datasets/medical_catalog_data.dart';
import 'datasets/university_boards_catalog_data.dart';
import 'master_catalog_categories.dart';

/// Central in-memory registry and fast search index for Student OS Catalog 2.0.
///
/// Hierarchy:
/// Category (18 Master Categories)
///   ↓
/// Family (Exam / Course Family)
///   ↓
/// Program (Course / Exam)
///   ↓
/// Level (Stage / Stream / Group / Year)
///   ↓
/// Paper (Subject / Paper)
class MasterCatalogRegistry {
  MasterCatalogRegistry._() {
    _initialize();
  }

  static final MasterCatalogRegistry instance = MasterCatalogRegistry._();

  final Map<String, CatalogCategory2> _categories = {};
  final Map<String, CatalogFamily> _families = {};
  final Map<String, CatalogProgram> _programs = {};
  final Map<String, List<CatalogFamily>> _categoryFamilies = {};
  final Map<String, List<CatalogProgram>> _familyPrograms = {};
  final Map<String, List<CatalogProgram>> _categoryPrograms = {};

  bool _initialized = false;

  void _initialize() {
    if (_initialized) return;

    // 1. Categories
    for (final cat in MasterCatalogCategories.getAllCategories()) {
      _categories[cat.id] = cat;
      _categoryFamilies[cat.id] = [];
      _categoryPrograms[cat.id] = [];
    }

    // 2. Aggregate Families
    final allFamilies = [
      ...CommerceFinanceCatalogData.getFamilies(),
      ...EngineeringCatalogData.getFamilies(),
      ...MedicalCatalogData.getFamilies(),
      ...LawCatalogData.getFamilies(),
      ...ManagementCatalogData.getFamilies(),
      ...GovernmentCatalogData.getFamilies(),
      ...UniversityBoardsCatalogData.getFamilies(),
    ];

    for (final f in allFamilies) {
      _families[f.id] = f;
      _categoryFamilies.putIfAbsent(f.categoryId, () => []).add(f);
      _familyPrograms[f.id] = [];
    }

    // 3. Aggregate Programs
    final allPrograms = [
      ...CommerceFinanceCatalogData.getPrograms(),
      ...EngineeringCatalogData.getPrograms(),
      ...MedicalCatalogData.getPrograms(),
      ...LawCatalogData.getPrograms(),
      ...ManagementCatalogData.getPrograms(),
      ...GovernmentCatalogData.getPrograms(),
      ...UniversityBoardsCatalogData.getPrograms(),
    ];

    for (final p in allPrograms) {
      _programs[p.id] = p;
      _familyPrograms.putIfAbsent(p.familyId, () => []).add(p);
      _categoryPrograms.putIfAbsent(p.categoryId, () => []).add(p);
    }

    _initialized = true;
  }

  // ─── Queries ──────────────────────────────────────────────────────────

  List<CatalogCategory2> get allCategories {
    _initialize();
    return _categories.values.where((c) => c.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  CatalogCategory2? getCategoryById(String id) {
    _initialize();
    return _categories[id];
  }

  List<CatalogFamily> get allFamilies {
    _initialize();
    return _families.values.where((f) => f.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<CatalogFamily> getFamiliesByCategory(String categoryId) {
    _initialize();
    return (_categoryFamilies[categoryId] ?? [])
        .where((f) => f.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  CatalogFamily? getFamilyById(String id) {
    _initialize();
    return _families[id];
  }

  List<CatalogProgram> get allPrograms {
    _initialize();
    return _programs.values.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<CatalogProgram> getProgramsByFamily(String familyId) {
    _initialize();
    return (_familyPrograms[familyId] ?? [])
        .where((p) => p.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<CatalogProgram> getProgramsByCategory(String categoryId) {
    _initialize();
    return (_categoryPrograms[categoryId] ?? [])
        .where((p) => p.isActive)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  CatalogProgram? getProgramById(String id) {
    _initialize();
    return _programs[id];
  }

  List<CatalogProgram> get popularPrograms {
    _initialize();
    return _programs.values.where((p) => p.isActive && p.isPopular).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // ─── Search ───────────────────────────────────────────────────────────

  /// Fast offline search across program titles, aliases, families, categories, and subject names.
  /// Supports multi-token queries like "GATE CSE" → matches if all tokens appear somewhere.
  List<CatalogProgram> search(
    String query, {
    String? categoryId,
    String? familyId,
  }) {
    _initialize();
    final clean = query.trim().toLowerCase();

    var candidates = allPrograms;
    if (categoryId != null && categoryId.isNotEmpty) {
      candidates = candidates.where((p) => p.categoryId == categoryId).toList();
    }
    if (familyId != null && familyId.isNotEmpty) {
      candidates = candidates.where((p) => p.familyId == familyId).toList();
    }

    if (clean.isEmpty) return candidates;

    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    bool matchesToken(CatalogProgram program, String token) {
      if (program.title.toLowerCase().contains(token)) return true;
      if (program.shortTitle?.toLowerCase().contains(token) ?? false) return true;
      if (program.code?.toLowerCase().contains(token) ?? false) return true;
      if (program.authority?.toLowerCase().contains(token) ?? false) return true;
      for (final alias in program.aliases) {
        if (alias.toLowerCase().contains(token)) return true;
      }
      final family = _families[program.familyId];
      if (family != null) {
        if (family.title.toLowerCase().contains(token)) return true;
        if (family.shortTitle?.toLowerCase().contains(token) ?? false) return true;
        for (final alias in family.aliases) {
          if (alias.toLowerCase().contains(token)) return true;
        }
      }
      for (final level in program.levels) {
        if (level.title.toLowerCase().contains(token)) return true;
        if (level.code?.toLowerCase().contains(token) ?? false) return true;
        for (final paper in level.allPapers) {
          if (paper.title.toLowerCase().contains(token)) return true;
          if (paper.shortTitle?.toLowerCase().contains(token) ?? false) return true;
          if (paper.code?.toLowerCase().contains(token) ?? false) return true;
        }
      }
      return false;
    }

    return candidates.where((program) {
      // All tokens must match somewhere
      for (final token in tokens) {
        if (!matchesToken(program, token)) return false;
      }
      return true;
    }).toList();
  }

  // ─── Paper Resolution ─────────────────────────────────────────────────

  /// Resolves all candidate papers for a program and selected level/sub-level.
  Map<String, List<CatalogPaper>> resolvePapers({
    required String programId,
    String? levelId,
    String? subLevelId,
  }) {
    _initialize();
    final program = getProgramById(programId);
    if (program == null || program.levels.isEmpty) {
      return {'compulsory': [], 'optional': []};
    }

    final papers = <CatalogPaper>[];
    final seen = <String>{};

    void addPaper(CatalogPaper p) {
      if (seen.add(p.id)) {
        papers.add(p);
      }
    }

    if (subLevelId != null && subLevelId.isNotEmpty) {
      // Look up sub-level
      for (final l in program.levels) {
        final found = l.findLevelById(subLevelId);
        if (found != null) {
          for (final p in found.allPapers) {
            addPaper(p);
          }
          break;
        }
      }
    } else if (levelId != null && levelId.isNotEmpty) {
      for (final l in program.levels) {
        final found = l.findLevelById(levelId);
        if (found != null) {
          for (final p in found.allPapers) {
            addPaper(p);
          }
          break;
        }
      }
    } else {
      // Default to first level
      for (final p in program.levels.first.allPapers) {
        addPaper(p);
      }
    }

    final compulsory = <CatalogPaper>[];
    final optional = <CatalogPaper>[];

    for (final p in papers) {
      if (p.isCompulsory) {
        compulsory.add(p);
      } else {
        optional.add(p);
      }
    }

    return {
      'compulsory': compulsory,
      'optional': optional,
    };
  }
}
