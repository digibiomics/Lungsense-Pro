import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/utils/paged.dart';
import 'package:lungsense_pro/features/collection/data/models/collection_models.dart';
import 'package:lungsense_pro/features/collection/domain/entities/collection_session.dart';
import 'package:lungsense_pro/features/collection/domain/repositories/collection_repository.dart';
import 'package:lungsense_pro/features/collection/domain/services/draft_visibility.dart';
import 'package:lungsense_pro/features/collection/presentation/cubit/collection_events.dart';
import 'package:lungsense_pro/features/collection/presentation/cubit/collection_session_cubit.dart';
import 'package:lungsense_pro/features/collection/presentation/cubit/list_cubits.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/collection_fakes.dart';

class _MockRepo extends Mock implements CollectionRepository {}

// Drafts the app hides: removed on this device, or not finished the day
// they started. The API cannot delete sessions (KI-25).
void main() {
  final now = DateTime(2026, 10, 28, 15);
  final yesterday = DateTime(2026, 10, 27, 18);

  SessionSummary row(
    String id, {
    SessionStatus status = SessionStatus.draft,
    DateTime? startedAt,
  }) => SessionSummary(
    id: id,
    patientId: 'p-1',
    studyId: 'LS-0142',
    status: status,
    counts: const SessionCounts(),
    startedAt: startedAt,
  );

  group('DraftVisibility', () {
    test('a draft expires once the day it started is over', () {
      expect(
        DraftVisibility.isExpired(row('a', startedAt: yesterday), now),
        isTrue,
      );
      expect(
        DraftVisibility.isExpired(
          row('b', startedAt: DateTime(2026, 10, 28, 0, 5)),
          now,
        ),
        isFalse,
      );
      expect(
        DraftVisibility.isExpired(
          row('c', status: SessionStatus.completed, startedAt: yesterday),
          now,
        ),
        isFalse,
      );
      expect(DraftVisibility.isExpired(row('d'), now), isFalse);
    });

    test('hides removed and expired drafts, keeps submitted ones', () async {
      final store = MemoryHiddenDraftsStore();
      final v = DraftVisibility(store, clock: () => now);
      await v.hide('removed');
      final out = await v.visible([
        row('today', startedAt: now),
        row('removed', startedAt: now),
        row('old', startedAt: yesterday),
        row('done', status: SessionStatus.completed, startedAt: yesterday),
      ]);
      expect(out.map((s) => s.id), ['today', 'done']);
      expect(await store.read(), {'removed'});
    });

    test('keeps only the newest removed ids', () async {
      final store = MemoryHiddenDraftsStore();
      final v = DraftVisibility(store, clock: () => now);
      for (var i = 0; i <= DraftVisibility.maxKept; i++) {
        await v.hide('s$i');
      }
      final ids = await store.read();
      expect(ids.length, DraftVisibility.maxKept);
      expect(ids.contains('s0'), isFalse);
    });
  });

  group('cubits', () {
    late _MockRepo repo;
    late DraftVisibility drafts;

    setUp(() {
      repo = _MockRepo();
      drafts = DraftVisibility(MemoryHiddenDraftsStore(), clock: () => now);
    });

    test('session list skips pages of hidden drafts and pages by rows '
        'read', () async {
      final old = [
        for (var i = 0; i < 50; i++) row('o$i', startedAt: yesterday),
      ];
      when(() => repo.listSessions(status: SessionStatus.draft, offset: 0))
          .thenAnswer((_) async => Paged(items: old, total: 101));
      when(() => repo.listSessions(status: SessionStatus.draft, offset: 50))
          .thenAnswer(
            (_) async => Paged(
              items: [
                row('t1', startedAt: now),
                ...old.skip(1),
              ],
              total: 101,
            ),
          );
      when(() => repo.listSessions(status: SessionStatus.draft, offset: 100))
          .thenAnswer(
            (_) async => Paged(items: [row('t2', startedAt: now)], total: 101),
          );
      final cubit = SessionsCubit(repo, drafts: drafts);
      await cubit.setFilter(SessionFilter.drafts);
      expect(cubit.state.items.map((s) => s.id), ['t1']);
      expect(cubit.state.fetched, 100);
      expect(cubit.state.hasMore, isTrue);
      await cubit.loadMore();
      expect(cubit.state.items.map((s) => s.id), ['t1', 't2']);
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    });

    test('dashboard shows up to three drafts still open today', () async {
      when(() => repo.listSessions(status: SessionStatus.draft, limit: 20))
          .thenAnswer(
            (_) async => Paged(
              items: [
                row('o1', startedAt: yesterday),
                for (var i = 0; i < 4; i++) row('t$i', startedAt: now),
              ],
              total: 5,
            ),
          );
      when(() => repo.dashboard()).thenAnswer(
        (_) async => CollectionModels.dashboardFromJson(dashboardJson()),
      );
      final cubit = DashboardCubit(repo, drafts: drafts);
      await cubit.load();
      expect(cubit.state.drafts.map((s) => s.id), ['t0', 't1', 't2']);
      await cubit.close();
    });

    test('removing a draft hides it and tells the lists', () async {
      when(() => repo.getSession('s-1')).thenAnswer(
        (_) async => CollectionModels.sessionFromJson(sessionJson()),
      );
      final events = CollectionEvents();
      final changed = expectLater(events.changes, emits('s-1'));
      final cubit = CollectionSessionCubit(
        repo,
        's-1',
        events: events,
        drafts: drafts,
      );
      await cubit.load();
      expect(cubit.canRemoveDraft, isTrue);
      await cubit.removeDraft();
      await changed;
      expect(await drafts.visible([cubit.state.session!.summary]), isEmpty);
      await cubit.close();
      await events.dispose();
    });

    test('a submitted session cannot be removed', () async {
      when(() => repo.getSession('s-1')).thenAnswer(
        (_) async =>
            CollectionModels.sessionFromJson(sessionJson(status: 'completed')),
      );
      final cubit = CollectionSessionCubit(repo, 's-1', drafts: drafts);
      await cubit.load();
      expect(cubit.canRemoveDraft, isFalse);
      await cubit.close();
    });
  });
}
