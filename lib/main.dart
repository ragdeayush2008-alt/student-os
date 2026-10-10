import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_shell_controller.dart';
import 'features/widgets/services/widget_data_service.dart';
import 'features/widgets/widget_link_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase BEFORE runApp so the client exists when AuthService
  // (created inside StudentOsApp) subscribes. Without this, client stays
  // null and every email/Google sign-in fails with "unknown" error.
  // Errors are caught inside the service (failed state) — never crash boot.
  final initFuture = SupabaseService.instance.initialize();
  // Home-screen widgets: tap handling (safe no-op on web/unsupported).
  WidgetLinkHandler.init();
  WidgetDataService.instance.init();
  runApp(StudentOsApp(controller: AppShellController()));
  await initFuture;
}
