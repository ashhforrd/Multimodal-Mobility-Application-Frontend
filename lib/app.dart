import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/active_navigation_screen.dart';
import 'features/navigation/presentation/route_preview_screen.dart';
import 'features/navigation/presentation/search_destination_screen.dart';
import 'features/recovery/presentation/route_recovery_view.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SearchDestinationScreen()),
    GoRoute(path: '/preview', builder: (_, __) => const RoutePreviewScreen()),
    GoRoute(
        path: '/navigation',
        builder: (_, __) => const ActiveNavigationScreen()),
    GoRoute(path: '/recovery', builder: (_, __) => const RouteRecoveryView()),
  ],
);

class LangkahSahabatApp extends StatelessWidget {
  const LangkahSahabatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Langkah Sahabat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        builder: (context, child) => ColoredBox(
          color: const Color(0xFFE8EEF7),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child!,
            ),
          ),
        ),
      );
}
