import 'package:flutter_test/flutter_test.dart';

import 'package:student_os/core/config/app_config.dart';
import 'package:student_os/core/services/supabase_service.dart';

void main() {
  group('AppConfig — Supabase configuration detection', () {
    test('empty credentials result in "not configured"', () {
      expect(AppConfig.isConfiguredFor('', ''), isFalse);
    });

    test('partial configuration is treated as invalid/not configured', () {
      expect(
        AppConfig.isConfiguredFor('https://project.supabase.co', ''),
        isFalse,
      );
      expect(AppConfig.isConfiguredFor('', 'anon-key'), isFalse);
    });

    test('configuration detection works when both values are present', () {
      expect(
        AppConfig.isConfiguredFor('https://project.supabase.co', 'anon-key'),
        isTrue,
      );
    });
  });

  group('SupabaseService — unconfigured path', () {
    test(
      'marks not configured and never crashes when credentials are absent',
      () async {
        SupabaseService.instance.resetForTesting();
        await SupabaseService.instance.initialize(url: '', anonKey: '');

        expect(
          SupabaseService.instance.currentState,
          SupabaseInitState.notConfigured,
        );
        expect(SupabaseService.instance.client, isNull);
      },
    );
  });
}
