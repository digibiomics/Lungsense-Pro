import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lungsense_pro/core/theme/app_theme.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';

/// Pumps [child] at '/' inside a router (other paths render a stub), with
/// the app theme and the given [session] provided.
Future<void> pumpPage(
  WidgetTester tester,
  Widget child, {
  required SessionCubit session,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/:other',
        builder: (_, s) => Scaffold(body: Text('route:${s.uri.path}')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    BlocProvider.value(
      value: session,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
}
