import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/storage/token_storage.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/session_usecases.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';

final GetIt sl = GetIt.instance;

/// Composition root. [storage] and [dio] are overridable for tests.
Future<void> configureDependencies({TokenStorage? storage, Dio? dio}) async {
  await sl.reset();

  final tokenStorage = storage ?? SecureTokenStorage();
  final client = dio ?? createDio();
  final remote = AuthRemoteDataSource(client);
  final repo = AuthRepositoryImpl(remote: remote, storage: tokenStorage);

  client.interceptors.add(
    AuthInterceptor(dio: client, storage: tokenStorage, refresher: repo),
  );

  sl
    ..registerSingleton<TokenStorage>(tokenStorage)
    ..registerSingleton<Dio>(client)
    ..registerSingleton<AuthRepository>(repo)
    ..registerLazySingleton(() => SignInWithEmail(sl()))
    ..registerLazySingleton(() => RestoreSession(sl()))
    ..registerLazySingleton(() => SignOut(sl()))
    ..registerLazySingleton(() => ResendConfirmation(sl()))
    ..registerSingleton<SessionCubit>(
      SessionCubit(
        restoreSession: RestoreSession(repo),
        signOut: SignOut(repo),
        repository: repo,
      ),
    );
}
