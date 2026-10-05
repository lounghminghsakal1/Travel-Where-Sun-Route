import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/results/presentation/screens/results_screen.dart';
import '../../features/route_input/presentation/screens/route_input_screen.dart';
import '../../features/seat_scoring/presentation/screens/seat_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', pageBuilder: (_, state) => _fadeSlide(state, const RouteInputScreen())),
    GoRoute(path: '/results', pageBuilder: (_, state) => _fadeSlide(state, const ResultsScreen())),
    GoRoute(
      path: '/seat/:seatId',
      pageBuilder: (_, state) => _fadeSlide(
        state,
        SeatDetailScreen(seatId: state.pathParameters['seatId']!),
      ),
    ),
    GoRoute(path: '/settings', pageBuilder: (_, state) => _fadeSlide(state, const SettingsScreen())),
  ],
);
