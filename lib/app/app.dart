import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';
import 'router.dart';

class LungSenseProApp extends StatefulWidget {
  const LungSenseProApp({super.key, required this.session});
  final SessionCubit session;

  @override
  State<LungSenseProApp> createState() => _LungSenseProAppState();
}

class _LungSenseProAppState extends State<LungSenseProApp> {
  late final GoRouter _router = createRouter(widget.session);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.session,
      child: MaterialApp.router(
        title: 'LungSense Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
