import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_os/core/design/goal_icon_mapping.dart';

void main() {
  group('GoalIconMapping — no lightning, goal-specific identity', () {
    test('never returns bolt/lightning icon', () {
      const titles = [
        'JEE Main',
        'JEE Advanced',
        'GATE 2026',
        'NEET UG',
        'NEET PG',
        'CLAT UG',
        'CAT',
        'UPSC Civil Services (IAS / IPS / IFS)',
        'SSC CGL (Combined Graduate Level)',
        'CBSE Class 10',
        'Unknown Exam XYZ',
        '',
      ];
      for (final t in titles) {
        final icon = GoalIconMapping.getIconForGoal(t);
        expect(icon, isNot(equals(Icons.bolt_rounded)),
            reason: 'Title "$t" must not map to lightning');
        expect(icon, isNot(equals(Icons.flash_on_rounded)),
            reason: 'Title "$t" must not map to flash');
      }
    });

    test('JEE variants map to engineering visuals', () {
      expect(GoalIconMapping.getIconForGoal('JEE Main'),
          equals(Icons.precision_manufacturing_rounded));
      expect(GoalIconMapping.getIconForGoal('JEE Advanced'),
          equals(Icons.rocket_launch_rounded));
    });

    test('GATE with year suffix still maps to engineering', () {
      expect(GoalIconMapping.getIconForGoal('GATE 2026'),
          equals(Icons.settings_input_component_rounded));
    });

    test('NEET maps to medical visuals', () {
      expect(GoalIconMapping.getIconForGoal('NEET UG'),
          equals(Icons.monitor_heart_rounded));
      expect(GoalIconMapping.getIconForGoal('NEET PG'),
          equals(Icons.psychology_rounded));
    });

    test('UPSC long title maps to government', () {
      expect(
          GoalIconMapping.getIconForGoal(
              'UPSC Civil Services (IAS / IPS / IFS)'),
          equals(Icons.account_balance_rounded));
    });

    test('category labels are meaningful', () {
      expect(GoalIconMapping.getCategoryForGoal('JEE Main'),
          equals('Engineering'));
      expect(GoalIconMapping.getCategoryForGoal('NEET UG'),
          equals('Medical'));
      expect(
          GoalIconMapping.getCategoryForGoal(
              'UPSC Civil Services (IAS / IPS / IFS)'),
          equals('Government'));
    });

    test('tints stay within green family', () {
      const titles = ['JEE Main', 'NEET UG', 'CAT', 'UPSC'];
      for (final t in titles) {
        final c = GoalIconMapping.getTintForGoal(t);
        // Green channel should dominate red/blue for emerald/sage family.
        expect(c.g >= c.r, isTrue,
            reason: 'Tint for "$t" should be green-dominant');
      }
    });
  });
}
