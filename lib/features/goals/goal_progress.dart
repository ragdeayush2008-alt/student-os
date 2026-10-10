/// Truthful goal progress derived from real controllers — never invented percentages.
class GoalProgress {
  final double current; // actual value from source controller
  final double target; // user-set target

  GoalProgress({required this.current, required this.target});

  double get fraction => target <= 0 ? 0 : (current / target).clamp(0, 1);
  double get percentage => fraction * 100;
  double get remaining => (target - current).clamp(0, double.infinity);
  bool get isComplete => fraction >= 1.0;
}
