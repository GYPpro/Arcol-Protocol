import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'views/login/login_view.dart';
import 'views/guest/guest_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/time_management/time_management_view.dart';
import 'views/asset_monitor/asset_monitor_view.dart';
import 'views/site_routes/site_routes_view.dart';
import 'views/server_monitor/server_monitor_view.dart';
import 'views/rss/rss_view.dart';
import 'views/settings/settings_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/guest',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isGuest = state.matchedLocation == '/guest';

      if (!isLoggedIn && !isGuest) {
        return '/guest';
      }
      
      if (isLoggedIn && (isLoggingIn || isGuest)) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/guest',
        builder: (context, state) => const GuestView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/time-management',
        builder: (context, state) => const TimeManagementView(),
      ),
      GoRoute(
        path: '/assets',
        builder: (context, state) => const AssetMonitorView(),
      ),
      GoRoute(
        path: '/site-routes',
        builder: (context, state) => const SiteRoutesView(),
      ),
      GoRoute(
        path: '/server-monitor',
        builder: (context, state) => const ServerMonitorView(),
      ),
      GoRoute(
        path: '/rss',
        builder: (context, state) => const RssView(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );
});

class ArcolProtocolApp extends ConsumerWidget {
  const ArcolProtocolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Arcol Protocol',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
