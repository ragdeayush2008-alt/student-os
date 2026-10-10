import '../../data/models/catalog/course_category.dart';
import '../../data/models/student_profile.dart';
import '../../features/auth/auth_service.dart';
import '../auth/auth_isolation.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

import 'package:flutter/foundation.dart';

/// Manages the student profile, onboarding state, and foundational data.
///
/// Scopes all data to the resolved user ([AuthIsolation] session first,
/// then [AuthService]). When identity is unknown the service stays
/// memory-only instead of using any shared fallback namespace.
/// When Supabase is available and the user is authenticated, cloud persistence
/// is attempted in addition to local persistence. Cloud failures are silent —
/// local data always remains authoritative.
class StudentService extends ChangeNotifier {
  StudentService._();

  /// Clears profile from memory (not persistent).
  void clearProfile() {
    _profile = StudentProfile();
    _loaded = false;
    notifyListeners();
  }

  static final StudentService instance = StudentService._();

  static const _profileKey = 'student_profile';

  StudentProfile _profile = StudentProfile();
  bool _loaded = false;
  bool _disposed = false;

  StudentProfile get profile => _profile;
  bool get isLoaded => _loaded;
  bool get isOnboardingComplete => _profile.isOnboardingComplete;

  /// Resolved user id, or `null` when unknown (logged out → memory-only,
  /// never a shared fallback namespace).
  String? get _userId {
    final authId = AuthIsolation.instance.currentUserId;
    if (authId != null && authId.isNotEmpty) return authId;
    return AuthService.instance.user?.id;
  }

  // ─── Loading ────────────────────────────────────────────────────────

  Future<void> load() async {
    await _loadLocal();
    // Mark loaded after local data is ready so the auth gate can proceed
    // immediately. Cloud sync runs in the background — a slow network must
    // never block app startup.
    _loaded = true;
    if (!_disposed) notifyListeners();
    _attemptCloudLoad();
  }

  Future<void> _loadLocal() async {
    final uid = _userId;
    if (uid == null) {
      // Unknown identity: keep any in-memory profile, never read or seed a
      // shared fallback namespace.
      return;
    }
    final json = await StorageService.instance.loadJson(
      userId: uid,
      key: _profileKey,
    );
    if (json != null) {
      _profile = StudentProfile.fromJson(json);
    } else {
      final user = AuthService.instance.user;
      final metaName = user?.userMetadata?['display_name'] as String? ?? '';
      _profile = StudentProfile(
        id: uid,
        email: user?.email ?? '',
        displayName: metaName,
      );
    }
  }

  Future<void> _attemptCloudLoad() async {
    final client = SupabaseService.instance.client;
    if (client == null || AuthService.instance.user == null) return;

    try {
      final uid = _userId;
      if (uid == null) return;
      final response = await client
          .from('student_profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (response != null) {
        final cloudProfile = StudentProfile.fromJson(response);
        final isCloudNewer = cloudProfile.updatedAt.isAfter(_profile.updatedAt);
        final wouldDowngradeOnboarding =
            _profile.isOnboardingComplete && !cloudProfile.isOnboardingComplete;
        if (isCloudNewer && !wouldDowngradeOnboarding) {
          _profile = cloudProfile;
          await _saveLocal();
        } else if (_profile.isOnboardingComplete &&
            !cloudProfile.isOnboardingComplete) {
          _attemptCloudSave();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentService] Cloud load failed: $e');
      // Silent failure — local data remains.
    }
  }

  // ─── Saving ─────────────────────────────────────────────────────────

  Future<void> _saveLocal() async {
    final uid = _userId;
    if (uid == null) return;
    await StorageService.instance.saveJson(
      userId: uid,
      key: _profileKey,
      json: _profile.toJson(),
    );
  }

  Future<void> _attemptCloudSave() async {
    final client = SupabaseService.instance.client;
    if (client == null || AuthService.instance.user == null) return;

    try {
      await client.from('student_profiles').upsert(_profile.toJson());
    } catch (e) {
      if (kDebugMode) debugPrint('[StudentService] Cloud save failed: $e');
    }
  }

  // ─── Profile mutations ──────────────────────────────────────────────

  Future<void> updateProfile(StudentProfile updated) async {
    _profile = updated;
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateDisplayName(String name) async {
    _profile = _profile.copyWith(displayName: name);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateCatalogEducation({
    required CourseCategory category,
    required String courseId,
    required String courseName,
    String? curriculumId,
    String? nodeId,
    String? authority,
    String? levelId,
    String? streamId,
    String? groupId,
    String? specializationId,
    List<String> selectedOptionalSubjectIds = const [],
    String? currentYear,
    String? institution,
  }) async {
    _profile = _profile.copyWith(
      catalogCategory: category,
      catalogCourseId: courseId,
      course: courseName,
      catalogCurriculumId: curriculumId,
      catalogNodeId: nodeId,
      catalogAuthority: authority,
      catalogLevelId: levelId,
      catalogStreamId: streamId,
      catalogGroupId: groupId,
      catalogSpecializationId: specializationId,
      selectedOptionalSubjectIds: selectedOptionalSubjectIds,
      currentYear: currentYear ?? _profile.currentYear,
      institution: institution ?? _profile.institution,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateEducationLevel(EducationLevel? level) async {
    _profile = _profile.copyWith(
      educationLevel: level,
      clearEducationLevel: level == null,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateAcademicContext({
    String? institution,
    String? course,
    String? currentYear,
  }) async {
    _profile = _profile.copyWith(
      institution: institution,
      course: course,
      currentYear: currentYear,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateGoals(List<StudentGoal> goals) async {
    _profile = _profile.copyWith(goals: goals);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateAcademicFocus(AcademicFocus? focus) async {
    _profile = _profile.copyWith(
      academicFocus: focus,
      clearAcademicFocus: focus == null,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> updateImportantDate(DateTime? date, String label) async {
    _profile = _profile.copyWith(
      importantDate: date,
      importantDateLabel: label,
      clearImportantDate: date == null,
    );
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> completeOnboarding() async {
    _profile = _profile.copyWith(onboardingState: OnboardingState.complete);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  Future<void> resetOnboarding() async {
    _profile = _profile.copyWith(onboardingState: OnboardingState.incomplete);
    await _saveLocal();
    if (!_disposed) notifyListeners();
    _attemptCloudSave();
  }

  /// Resets profile to defaults for new-user state.
  Future<void> resetProfile() async {
    _profile = StudentProfile(id: _userId ?? '');
    await _saveLocal();
    if (!_disposed) notifyListeners();
  }

  /// Initializes profile with auth user data without overwriting existing local data.
  Future<void> initializeFromAuth() async {
    final user = AuthService.instance.user;
    if (user == null) return;
    if (!_loaded) {
      await _loadLocal();
      _loaded = true;
    }
    final metaName = user.userMetadata?['display_name'] as String? ?? '';
    bool changed = false;
    var updated = _profile;
    if (updated.email.isEmpty && user.email != null && user.email!.isNotEmpty) {
      updated = updated.copyWith(email: user.email);
      changed = true;
    }
    if (updated.displayName.isEmpty && metaName.isNotEmpty) {
      updated = updated.copyWith(displayName: metaName);
      changed = true;
    }
    if (changed) {
      _profile = updated;
      await _saveLocal();
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
