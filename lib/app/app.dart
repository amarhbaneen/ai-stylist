import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../features/profile/profile_providers.dart';
import 'router.dart';

/// Root widget. Expects a `ProviderScope` above it (see bootstrap).
class AiStylistApp extends ConsumerStatefulWidget {
  const AiStylistApp({super.key});

  @override
  ConsumerState<AiStylistApp> createState() => _AiStylistAppState();
}

class _AiStylistAppState extends ConsumerState<AiStylistApp> {
  late final GoRouter _router = buildRouter(
    onboardingComplete: ref.read(onboardingCompleteAtLaunchProvider),
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Stylist',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}

/// Shown when the app cannot start (for example private storage is
/// unavailable). Contains no technical details; those go to the local log.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'AI Stylist could not open its storage on this device. '
                'Please check that there is free space, then restart the app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
