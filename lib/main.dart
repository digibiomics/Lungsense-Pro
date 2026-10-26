import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/config/api_config.dart';
import 'core/logging/app_logger.dart';
import 'features/authentication/presentation/cubit/session_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!ApiConfig.usesHttps) {
    AppLogger.debug(
      'API_BASE_URL is not HTTPS. Use only for development/testing; '
      'never with real credentials or patient data.',
    );
  }
  await configureDependencies();
  final session = sl<SessionCubit>()..restore();
  runApp(LungSenseProApp(session: session));
}
