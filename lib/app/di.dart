import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/storage/token_storage.dart';
import '../features/admin/data/datasources/admin_remote_data_source.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/admin/domain/usecases/admin_usecases.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/session_usecases.dart';
import '../features/authentication/presentation/cubit/session_cubit.dart';
import '../features/collection/data/datasources/collection_remote_data_source.dart';
import '../features/collection/data/device/device_services_impl.dart';
import '../features/collection/data/repositories/collection_repository_impl.dart';
import '../features/collection/domain/repositories/collection_repository.dart';
import '../features/collection/domain/services/device_services.dart';
import '../features/collection/presentation/cubit/collection_events.dart';
import '../features/patients/data/datasources/patient_remote_data_source.dart';
import '../features/patients/data/repositories/patient_repository_impl.dart';
import '../features/patients/domain/repositories/patient_repository.dart';
import '../features/patients/domain/usecases/patient_usecases.dart';

final GetIt sl = GetIt.instance;

/// Microphone, player, file picker and link opener. Tests pass fakes.
class DeviceServices {
  const DeviceServices({
    required this.capture,
    required this.inspector,
    required this.playback,
    required this.files,
    required this.links,
  });

  /// One per recorder screen (each owns its recorder).
  final AudioCapture Function() capture;
  final AudioInspector inspector;
  final AudioPlayback Function() playback;
  final FilePicking files;
  final LinkOpener links;

  static DeviceServices platform() => DeviceServices(
    capture: RecordAudioCapture.new,
    inspector: JustAudioInspector(),
    playback: JustAudioPlayback.new,
    files: SystemFilePicking(),
    links: ExternalLinkOpener(),
  );
}

/// Composition root. [storage], [dio] and [devices] are overridable for
/// tests. With a test [dio], storage uploads use the same HTTP adapter.
Future<void> configureDependencies({
  TokenStorage? storage,
  Dio? dio,
  DeviceServices? devices,
}) async {
  await sl.reset();

  final tokenStorage = storage ?? SecureTokenStorage();
  final client = dio ?? createDio();
  final uploads = createUploadDio();
  if (dio != null) uploads.httpClientAdapter = dio.httpClientAdapter;
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
    ..registerLazySingleton(() => RegisterAccount(sl()))
    ..registerLazySingleton(() => RequestPasswordReset(sl()))
    ..registerLazySingleton(() => ResetPassword(sl()))
    ..registerLazySingleton(() => CompleteAccountType(sl()))
    ..registerLazySingleton(() => RefreshProfile(sl()))
    ..registerSingleton<AdminRepository>(
      AdminRepositoryImpl(AdminRemoteDataSource(client)),
    )
    ..registerLazySingleton(() => ListDoctorApplications(sl()))
    ..registerLazySingleton(() => ApproveDoctor(sl()))
    ..registerLazySingleton(() => RejectDoctor(sl()))
    ..registerLazySingleton(() => ListUsers(sl()))
    ..registerLazySingleton(() => SetUserStatus(sl()))
    ..registerSingleton<PatientRepository>(
      PatientRepositoryImpl(PatientRemoteDataSource(client)),
    )
    ..registerLazySingleton(() => ListPatients(sl()))
    ..registerLazySingleton(() => GetPatient(sl()))
    ..registerLazySingleton(() => SavePatient(sl()))
    ..registerSingleton<CollectionRepository>(
      CollectionRepositoryImpl(CollectionRemoteDataSource(client, uploads)),
    )
    ..registerSingleton<CollectionEvents>(
      CollectionEvents(),
      dispose: (e) => e.dispose(),
    )
    ..registerSingleton<DeviceServices>(devices ?? DeviceServices.platform())
    ..registerSingleton<SessionCubit>(
      SessionCubit(
        restoreSession: RestoreSession(repo),
        signOut: SignOut(repo),
        repository: repo,
        refreshProfile: RefreshProfile(repo),
      ),
    );
}
