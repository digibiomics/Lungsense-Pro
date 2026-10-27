import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../domain/entities/recording.dart';
import '../cubit/step_cubits.dart';
import '../widgets/collection_mode.dart';
import '../widgets/collection_widgets.dart';

/// 21 Clinical context (Clinical.dc.html): optional notes and X-ray.
class ClinicalPage extends StatefulWidget {
  const ClinicalPage({super.key, required this.mode});
  final CollectionMode mode;

  @override
  State<ClinicalPage> createState() => _ClinicalPageState();
}

class _ClinicalPageState extends State<ClinicalPage> {
  final _notes = TextEditingController();
  bool _seeded = false;
  XrayView? _view;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _saveAndReview(ClinicalCubit cubit) async {
    final ok = await cubit.save(_notes.text);
    if (ok && mounted) {
      context.pushReplacement(
        widget.mode.stepPath(cubit.sessionId, CollectionRoute.review),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClinicalCubit, ClinicalState>(
      listenWhen: (a, b) => !_seeded && b.session != null,
      listener: (context, state) {
        _seeded = true;
        _notes.text = state.session!.summary.notes ?? '';
        setState(() {});
      },
      builder: (context, state) {
        final cubit = context.read<ClinicalCubit>();
        final busy = state.saving || state.uploading;
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LsCollectionHeader(
                  step: 3,
                  savedLabel: _seeded ? 'Draft saved' : null,
                  onBack: () => context.pop(),
                ),
                Expanded(
                  child: state.session == null
                      ? SessionLoadState(
                          failure: state.loadFailure,
                          onRetry: cubit.load,
                        )
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
                                      'Clinical context',
                                      style: LsText.screenTitle,
                                    ),
                                  ),
                                ),
                                const LsStatusPill(
                                  label: 'Optional',
                                  tone: LsPillTone.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.mode.isPatient
                                  ? 'Add anything your study team should '
                                        'know about today. Skip if there\'s '
                                        'nothing to add.'
                                  : 'Add notes for the research team. Skip '
                                        'if there\'s nothing to add.',
                              style: LsText.subtitle,
                            ),
                            const SizedBox(height: LsSpace.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Notes', style: LsText.label),
                                ),
                                Text(
                                  '${_notes.text.length} / ${ClinicalCubit.maxNotes}',
                                  style: LsText.helper,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const Key('clinical_notes'),
                              controller: _notes,
                              enabled: !busy,
                              minLines: 4,
                              maxLines: 8,
                              maxLength: ClinicalCubit.maxNotes,
                              buildCounter: (
                                _, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                              style: LsText.body,
                              decoration: const InputDecoration(
                                hintText: 'Optional',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            if (state.saveFailure != null) ...[
                              const SizedBox(height: LsSpace.sm),
                              LsBanner(
                                tone: LsBannerTone.error,
                                title: 'Notes not saved.',
                                body: FailureMessages.generic(
                                  state.saveFailure!,
                                ).body,
                              ),
                            ],
                            const SizedBox(height: LsSpace.lg),
                            _XraySection(
                              state: state,
                              view: _view,
                              onView: (v) =>
                                  setState(() => _view = _view == v ? null : v),
                              onAttach: busy
                                  ? null
                                  : () => cubit.attachXray(view: _view),
                              onRemove: cubit.removeXray,
                            ),
                          ],
                        ),
                ),
                if (state.session != null)
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
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: LsButton(
                            label: 'Skip',
                            variant: LsButtonVariant.secondary,
                            onPressed: busy
                                ? null
                                : () => context.pushReplacement(
                                    widget.mode.stepPath(
                                      cubit.sessionId,
                                      CollectionRoute.review,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: LsSpace.sm),
                        Expanded(
                          child: LsButton(
                            key: const Key('clinical_save'),
                            label: 'Save & review',
                            loading: state.saving,
                            loadingLabel: 'Saving…',
                            onPressed: state.uploading
                                ? null
                                : () => _saveAndReview(cubit),
                          ),
                        ),
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
}

class _XraySection extends StatelessWidget {
  const _XraySection({
    required this.state,
    required this.view,
    required this.onView,
    required this.onAttach,
    required this.onRemove,
  });

  final ClinicalState state;
  final XrayView? view;
  final ValueChanged<XrayView> onView;
  final VoidCallback? onAttach;
  final ValueChanged<XrayImage> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(LsRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: LsTint.iconDisc,
                  borderRadius: BorderRadius.circular(LsRadius.control),
                ),
                child: const Icon(Icons.image_outlined),
              ),
              const SizedBox(width: LsSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chest X-ray', style: LsText.listTitle),
                    Text(
                      'Optional · if one exists for this visit',
                      style: LsText.helper,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: LsSize.minTouch,
                child: OutlinedButton(
                  key: const Key('xray_attach'),
                  onPressed: onAttach,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LsRadius.small),
                    ),
                  ),
                  child: const Text('Attach'),
                ),
              ),
            ],
          ),
          const SizedBox(height: LsSpace.sm),
          Text('View (optional)', style: LsText.helper),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in XrayView.values)
                ChoiceChip(
                  label: Text(v.label),
                  selected: view == v,
                  onSelected: (_) => onView(v),
                  selectedColor: LsTint.chosen,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: view == v
                        ? AppColors.supportingGreen
                        : AppColors.border,
                  ),
                  showCheckmark: false,
                  labelStyle: LsText.label,
                ),
            ],
          ),
          if (state.uploading) ...[
            const SizedBox(height: LsSpace.sm),
            Text(
              'Uploading… ${(state.progress * 100).round()}%',
              style: LsText.label,
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 6,
              color: AppColors.info,
              backgroundColor: AppColors.border,
            ),
          ],
          if (state.xrayFailure != null) ...[
            const SizedBox(height: LsSpace.sm),
            LsBanner(
              tone: LsBannerTone.error,
              title: 'X-ray not saved.',
              body:
                  state.xrayFailure!.message ??
                  FailureMessages.generic(state.xrayFailure!).body,
            ),
          ],
          for (final x in state.xrays) ...[
            const Divider(height: LsSpace.lg, color: AppColors.border),
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: LsSpace.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        x.fileName ?? 'Chest X-ray',
                        style: LsText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        [
                          ?x.view?.label,
                          if (x.uploadedAt != null)
                            'Uploaded ${LsDates.time(x.uploadedAt!)}',
                        ].join(' · '),
                        style: LsText.helper,
                      ),
                    ],
                  ),
                ),
                state.removingId == x.id
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : LsLinkButton(
                        label: 'Remove',
                        onPressed: state.removingId == null
                            ? () => onRemove(x)
                            : null,
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
