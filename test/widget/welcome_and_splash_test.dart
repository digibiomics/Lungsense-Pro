import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/assets/app_assets.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/features/authentication/domain/repositories/auth_repository.dart';
import 'package:lungsense_pro/features/authentication/domain/usecases/session_usecases.dart';
import 'package:lungsense_pro/features/authentication/presentation/cubit/session_cubit.dart';
import 'package:lungsense_pro/features/authentication/presentation/pages/splash_page.dart';
import 'package:lungsense_pro/features/authentication/presentation/pages/welcome_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late SessionCubit session;

  setUp(() {
    repo = MockAuthRepository();
    when(() => repo.sessionExpired).thenAnswer((_) => const Stream.empty());
    session = SessionCubit(
      restoreSession: RestoreSession(repo),
      signOut: SignOut(repo),
      repository: repo,
    );
  });

  tearDown(() => session.close());

  bool usesAsset(WidgetTester t, String path) => t
      .widgetList<Image>(find.byType(Image))
      .any(
        (i) =>
            i.image is AssetImage && (i.image as AssetImage).assetName == path,
      );

  testWidgets('welcome uses supplied brand assets and both actions', (t) async {
    await pumpPage(t, const WelcomePage(), session: session);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(
      find.textContaining('separate from LungSense Wellness'),
      findsOneWidget,
    );
    expect(usesAsset(t, AppAssets.appIconTile), isTrue);
    expect(usesAsset(t, AppAssets.digibiomicsLogo), isTrue);
    expect(find.textContaining('Google'), findsNothing);
  });

  testWidgets('welcome fits a small phone without overflow', (t) async {
    await pumpPage(
      t,
      const WelcomePage(),
      session: session,
      size: const Size(320, 568),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('splash shows a retry after an offline restore', (t) async {
    when(() => repo.restoreSession())
        .thenThrow(const Failure(kind: FailureKind.network));
    await session.restore();
    await pumpPage(t, const SplashPage(), session: session);
    expect(usesAsset(t, AppAssets.logoStacked), isTrue);
    expect(find.textContaining('Can\'t reach LungSense Pro.'), findsOneWidget);

    when(() => repo.restoreSession()).thenAnswer((_) async => null);
    await t.tap(find.text('Try again'));
    await t.pump();
    verify(() => repo.restoreSession()).called(2);
  });
}
