import 'package:flutter/widgets.dart';
import 'density_profile.dart';

class StudentOSDensityScope extends InheritedWidget {
  final DensityProfile density;

  const StudentOSDensityScope({
    super.key,
    required this.density,
    required super.child,
  });

  static DensityProfile of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StudentOSDensityScope>()?.density ?? DensityProfile.standard;
  }

  @override
  bool updateShouldNotify(StudentOSDensityScope oldWidget) {
    return oldWidget.density != density;
  }
}
