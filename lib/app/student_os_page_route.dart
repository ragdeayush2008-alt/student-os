import 'package:flutter/material.dart';
import '../core/animations/app_page_transitions.dart';

class StudentOSPageRoute<T> extends PageRouteBuilder<T> {
  StudentOSPageRoute({
    required Widget Function(BuildContext) builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return const AppPageTransitions().buildTransitions<T>(
              ModalRoute.of(context) as PageRoute<T>,
              context,
              animation,
              secondaryAnimation,
              child,
            );
          },
        );
}
