import 'package:flutter/material.dart';
import 'catalog/course_category.dart';

/// Education level options for student profiles.
enum EducationLevel {
  highSchool('High School'),
  undergraduate('Undergraduate'),
  graduate('Graduate'),
  postgraduate('Postgraduate'),
  professional('Professional'),
  selfDirected('Self-Directed');

  const EducationLevel(this.label);
  final String label;
}

/// Foundational student goals — multiple can be selected.
enum StudentGoal {
  academicExcellence('Academic Excellence', Icons.school_rounded),
  examPreparation('Exam Preparation', Icons.quiz_rounded),
  consistency('Consistency', Icons.local_fire_department_rounded),
  productivity('Productivity', Icons.bolt_rounded),
  skillDevelopment('Skill Development', Icons.psychology_rounded),
  wellbeing('Balance & Wellbeing', Icons.spa_rounded);

  const StudentGoal(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Current academic focus areas.
enum AcademicFocus {
  examPrep('Exam Preparation', Icons.timer_outlined),
  catchingUp('Catching Up', Icons.refresh_rounded),
  assignments('Assignments & Projects', Icons.assignment_outlined),
  productivity('Daily Productivity', Icons.trending_up_rounded),
  balancedRoutine('Balanced Routine', Icons.balance_rounded),
  consistency('Building Consistency', Icons.repeat_rounded);

  const AcademicFocus(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Onboarding completion state.
enum OnboardingState { incomplete, complete }

/// Foundational student profile model.
///
/// Stores the student's identity, academic context, goals, and onboarding
/// state. Designed for local persistence with optional Supabase sync.
class StudentProfile {
  StudentProfile({
    this.id = 'demo',
    this.displayName = '',
    this.email = '',
    this.educationLevel,
    this.institution = '',
    this.course = '',
    this.currentYear = '',
    this.goals = const [],
    this.academicFocus,
    this.importantDate,
    this.importantDateLabel = '',
    this.onboardingState = OnboardingState.incomplete,
    this.catalogCategory,
    this.catalogCourseId,
    this.catalogCurriculumId,
    this.catalogNodeId,
    this.catalogAuthority,
    this.catalogLevelId,
    this.catalogStreamId,
    this.catalogGroupId,
    this.catalogSpecializationId,
    this.selectedOptionalSubjectIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  String displayName;
  String email;
  EducationLevel? educationLevel;
  String institution;
  String course;
  String currentYear;
  List<StudentGoal> goals;
  AcademicFocus? academicFocus;
  DateTime? importantDate;
  String importantDateLabel;
  OnboardingState onboardingState;

  // Course Catalog reference linkage
  CourseCategory? catalogCategory;
  String? catalogCourseId;
  String? catalogCurriculumId;
  String? catalogNodeId;
  String? catalogAuthority;
  String? catalogLevelId;
  String? catalogStreamId;
  String? catalogGroupId;
  String? catalogSpecializationId;
  List<String> selectedOptionalSubjectIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOnboardingComplete => onboardingState == OnboardingState.complete;
  bool get hasCatalogCourse => catalogCourseId != null && catalogCourseId!.isNotEmpty;

  String get initials {
    if (displayName.isEmpty) return '?';
    return displayName.substring(0, 1).toUpperCase();
  }

  String get displayLabel {
    if (displayName.isNotEmpty) return displayName;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Student';
  }

  String get academicSummary {
    final parts = <String>[];
    if (course.isNotEmpty) parts.add(course);
    if (institution.isNotEmpty) parts.add(institution);
    if (currentYear.isNotEmpty) parts.add(currentYear);
    if (parts.isEmpty && educationLevel != null) {
      parts.add(educationLevel!.label);
    }
    return parts.join(' · ');
  }

  StudentProfile copyWith({
    String? displayName,
    String? email,
    EducationLevel? educationLevel,
    String? institution,
    String? course,
    String? currentYear,
    List<StudentGoal>? goals,
    AcademicFocus? academicFocus,
    DateTime? importantDate,
    String? importantDateLabel,
    OnboardingState? onboardingState,
    CourseCategory? catalogCategory,
    String? catalogCourseId,
    String? catalogCurriculumId,
    String? catalogNodeId,
    String? catalogAuthority,
    String? catalogLevelId,
    String? catalogStreamId,
    String? catalogGroupId,
    String? catalogSpecializationId,
    List<String>? selectedOptionalSubjectIds,
    bool clearEducationLevel = false,
    bool clearImportantDate = false,
    bool clearAcademicFocus = false,
    bool clearCatalogCourse = false,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      educationLevel: clearEducationLevel
          ? null
          : (educationLevel ?? this.educationLevel),
      institution: institution ?? this.institution,
      course: course ?? this.course,
      currentYear: currentYear ?? this.currentYear,
      goals: goals ?? this.goals,
      academicFocus: clearAcademicFocus
          ? null
          : (academicFocus ?? this.academicFocus),
      importantDate: clearImportantDate
          ? null
          : (importantDate ?? this.importantDate),
      importantDateLabel: importantDateLabel ?? this.importantDateLabel,
      onboardingState: onboardingState ?? this.onboardingState,
      catalogCategory: clearCatalogCourse
          ? null
          : (catalogCategory ?? this.catalogCategory),
      catalogCourseId: clearCatalogCourse
          ? null
          : (catalogCourseId ?? this.catalogCourseId),
      catalogCurriculumId: clearCatalogCourse
          ? null
          : (catalogCurriculumId ?? this.catalogCurriculumId),
      catalogNodeId: clearCatalogCourse
          ? null
          : (catalogNodeId ?? this.catalogNodeId),
      catalogAuthority: clearCatalogCourse
          ? null
          : (catalogAuthority ?? this.catalogAuthority),
      catalogLevelId: clearCatalogCourse
          ? null
          : (catalogLevelId ?? this.catalogLevelId),
      catalogStreamId: clearCatalogCourse
          ? null
          : (catalogStreamId ?? this.catalogStreamId),
      catalogGroupId: clearCatalogCourse
          ? null
          : (catalogGroupId ?? this.catalogGroupId),
      catalogSpecializationId: clearCatalogCourse
          ? null
          : (catalogSpecializationId ?? this.catalogSpecializationId),
      selectedOptionalSubjectIds: clearCatalogCourse
          ? const []
          : (selectedOptionalSubjectIds ?? this.selectedOptionalSubjectIds),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'educationLevel': educationLevel?.name,
    'institution': institution,
    'course': course,
    'currentYear': currentYear,
    'goals': goals.map((g) => g.name).toList(),
    'academicFocus': academicFocus?.name,
    'importantDate': importantDate?.toIso8601String(),
    'importantDateLabel': importantDateLabel,
    'onboardingState': onboardingState.name,
    if (catalogCategory != null) 'catalogCategory': catalogCategory!.name,
    if (catalogCourseId != null) 'catalogCourseId': catalogCourseId,
    if (catalogCurriculumId != null) 'catalogCurriculumId': catalogCurriculumId,
    if (catalogNodeId != null) 'catalogNodeId': catalogNodeId,
    if (catalogAuthority != null) 'catalogAuthority': catalogAuthority,
    if (catalogLevelId != null) 'catalogLevelId': catalogLevelId,
    if (catalogStreamId != null) 'catalogStreamId': catalogStreamId,
    if (catalogGroupId != null) 'catalogGroupId': catalogGroupId,
    if (catalogSpecializationId != null)
      'catalogSpecializationId': catalogSpecializationId,
    if (selectedOptionalSubjectIds.isNotEmpty)
      'selectedOptionalSubjectIds': selectedOptionalSubjectIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: (json['id'] as String?) ?? 'demo',
    displayName: (json['displayName'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    educationLevel: json['educationLevel'] != null
        ? EducationLevel.values.firstWhere(
            (e) => e.name == json['educationLevel'],
            orElse: () => EducationLevel.undergraduate,
          )
        : null,
    institution: (json['institution'] as String?) ?? '',
    course: (json['course'] as String?) ?? '',
    currentYear: (json['currentYear'] as String?) ?? '',
    goals:
        (json['goals'] as List<dynamic>?)
            ?.map(
              (g) => StudentGoal.values.firstWhere(
                (goal) => goal.name == g,
                orElse: () => StudentGoal.academicExcellence,
              ),
            )
            .toList() ??
        [],
    academicFocus: json['academicFocus'] != null
        ? AcademicFocus.values.firstWhere(
            (f) => f.name == json['academicFocus'],
            orElse: () => AcademicFocus.balancedRoutine,
          )
        : null,
    importantDate: json['importantDate'] != null
        ? DateTime.parse(json['importantDate'] as String)
        : null,
    importantDateLabel: (json['importantDateLabel'] as String?) ?? '',
    onboardingState: json['onboardingState'] == 'complete'
        ? OnboardingState.complete
        : OnboardingState.incomplete,
    catalogCategory: json['catalogCategory'] != null
        ? CourseCategory.fromString(json['catalogCategory'] as String?)
        : null,
    catalogCourseId: json['catalogCourseId'] as String?,
    catalogCurriculumId: json['catalogCurriculumId'] as String?,
    catalogNodeId: json['catalogNodeId'] as String?,
    catalogAuthority: json['catalogAuthority'] as String?,
    catalogLevelId: json['catalogLevelId'] as String?,
    catalogStreamId: json['catalogStreamId'] as String?,
    catalogGroupId: json['catalogGroupId'] as String?,
    catalogSpecializationId: json['catalogSpecializationId'] as String?,
    selectedOptionalSubjectIds:
        (json['selectedOptionalSubjectIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );
}
