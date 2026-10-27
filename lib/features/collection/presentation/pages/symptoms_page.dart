import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../domain/entities/symptoms.dart';
import '../cubit/step_cubits.dart';
import '../widgets/collection_mode.dart';
import '../widgets/collection_widgets.dart';
import '../widgets/symptom_copy.dart';

/// 20 Symptoms (Symptoms.dc.html).
class SymptomsPage extends StatelessWidget {
  const SymptomsPage({super.key, required this.mode});
  final CollectionMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SymptomsCubit, SymptomsState>(
      builder: (context, state) {
        final cubit = context.read<SymptomsCubit>();
        final total = SymptomKey.values.length;
        final answered = state.ratings.ratedCount;
        final remaining = total - answered;
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LsCollectionHeader(
                  step: 2,
                  savedLabel: state.saved ? 'Answers saved' : null,
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: state.loading
                      ? const SessionLoadState(failure: null, onRetry: _noop)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            LsSpace.gutter,
                            LsSpace.xs,
                            LsSpace.gutter,
                            LsSpace.lg,
                          ),
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      'Symptoms today',
                                      style: LsText.screenTitle,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$answered of $total',
                                  key: const Key('symptoms_count'),
                                  style: LsText.label,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rate each one from 0 (none) to 3 (severe).',
                              style: LsText.subtitle,
                            ),
                            if (state.failure != null) ...[
                              const SizedBox(height: LsSpace.md),
                              LsBanner(
                                tone: LsBannerTone.error,
                                title: 'Answers not saved.',
                                body: FailureMessages.generic(state.failure!)
                                    .body,
                                actionLabel: answered == 0 ? 'Try again' : null,
                                onAction: cubit.load,
                              ),
                            ],
                            const SizedBox(height: LsSpace.md),
                            for (final k in SymptomKey.values) ...[
                              _SymptomCard(
                                symptom: k,
                                value: state.ratings[k],
                                highlight:
                                    state.tried && state.ratings[k] == null,
                                onChanged: (v) => cubit.rate(k, v),
                              ),
                              const SizedBox(height: LsSpace.sm),
                            ],
                          ],
                        ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    LsSpace.gutter,
                    LsSpace.sm,
                    LsSpace.gutter,
                    LsSpace.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LsButton(
                        key: const Key('symptoms_continue'),
                        label: 'Continue to context',
                        loading: state.saving,
                        loadingLabel: 'Saving…',
                        onPressed: state.loading
                            ? null
                            : () async {
                                final ok = await cubit.submit();
                                if (ok && context.mounted) {
                                  context.pushReplacement(
                                    mode.stepPath(
                                      cubit.sessionId,
                                      CollectionRoute.context,
                                    ),
                                  );
                                }
                              },
                      ),
                      if (remaining > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Rate $remaining more to continue. Choose 0 if a '
                          'symptom is absent.',
                          textAlign: TextAlign.center,
                          style: LsText.helper.copyWith(
                            color: state.tried
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _noop() {}
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.symptom,
    required this.value,
    required this.highlight,
    required this.onChanged,
  });

  final SymptomKey symptom;
  final int? value;
  final bool highlight;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final copy = symptomCopy[symptom]!;
    final hint = value == null ? null : copy.levels?[value!];
    return Container(
      key: Key('symptom_${symptom.api}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: highlight ? AppColors.error : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(copy.title, style: LsText.listTitle)),
              if (value == null)
                Text(
                  'Not rated',
                  style: LsText.helper.copyWith(
                    color: highlight
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (copy.description != null) ...[
            const SizedBox(height: 2),
            Text(copy.description!, style: LsText.helper),
          ],
          const SizedBox(height: 10),
          LsSeverityScale(
            value: value,
            names: severityNames,
            keyPrefix: 'rate_${symptom.api}',
            onChanged: onChanged,
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${ratingLabel(value!)}${hint == null ? '' : ':'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (hint != null) TextSpan(text: ' $hint'),
                ],
              ),
              style: LsText.bannerBody,
            ),
          ],
        ],
      ),
    );
  }
}
