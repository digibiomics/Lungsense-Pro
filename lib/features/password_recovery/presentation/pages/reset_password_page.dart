import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../cubit/password_recovery_cubits.dart';

/// 08 Reset password (ResetPassword.dc.html): email, 6-digit code,
/// new password + confirmation (client-side only, never sent).
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    this.initialEmail,
    required this.onDone,
    required this.doneLabel,
  });

  final String? initialEmail;
  final VoidCallback onDone;
  final String doneLabel;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ResetPasswordCubit>().submit(
      email: _email.text,
      otpCode: _code.text,
      newPassword: _password.text,
    );
  }

  void _newCode() => context.go(Routes.forgotPasswordFor(_email.text.trim()));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
      builder: (context, state) {
        final cubit = context.read<ResetPasswordCubit>();
        final busy = state.submitting || state.done;
        final codeBad = state.error == ResetError.invalidCode;
        final pwError =
            state.fieldErrors['new_password'] ?? state.fieldErrors['password'];
        final showBanner =
            state.error == ResetError.other ||
            (state.error == ResetError.rejected && pwError == null);
        return LsScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.login),
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Set a new password', style: LsText.pageTitle),
                const SizedBox(height: 6),
                Text(
                  'Enter the 6-digit code from your email and choose a new '
                  'password.',
                  style: LsText.subtitle,
                ),
                if (showBanner) ...[
                  const SizedBox(height: 20),
                  Builder(
                    builder: (_) {
                      final f = state.failure!;
                      final copy = state.error == ResetError.rejected
                          ? (
                              title: 'Password not accepted.',
                              body: f.message ?? 'Please try another password.',
                            )
                          : FailureMessages.generic(f);
                      return LsBanner(
                        tone: LsBannerTone.error,
                        title: copy.title,
                        body: copy.body,
                      );
                    },
                  ),
                ],
                const SizedBox(height: LsSpace.lg),
                LsTextField(
                  fieldKey: const Key('reset_email'),
                  label: 'Email address',
                  controller: _email,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: LsSpace.md),
                _OtpField(
                  controller: _code,
                  enabled: !busy,
                  invalid: codeBad,
                  onChanged: (_) => cubit.clearError(),
                ),
                const SizedBox(height: 6),
                if (codeBad)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'This code is invalid or has expired.',
                        style: LsText.helper.copyWith(color: AppColors.error),
                      ),
                      LsLinkButton(
                        label: 'Ask for a new code',
                        onPressed: _newCode,
                        style: LsText.helper.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Didn\'t get it?', style: LsText.helper),
                      LsLinkButton(
                        label: 'Send a new code',
                        onPressed: busy ? null : _newCode,
                        style: LsText.helper.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: LsSpace.sm),
                LsTextField(
                  fieldKey: const Key('reset_password'),
                  label: 'New password',
                  controller: _password,
                  obscure: true,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorText: pwError,
                  validator: Validators.newPassword,
                  onChanged: (_) => cubit.clearError(),
                ),
                const SizedBox(height: LsSpace.md),
                LsTextField(
                  fieldKey: const Key('reset_confirm'),
                  label: 'Confirm new password',
                  controller: _confirm,
                  obscure: true,
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _password.text
                      ? 'The passwords don\'t match.'
                      : null,
                  onSubmitted: (_) => _submit(),
                ),
                if (state.done) ...[
                  const SizedBox(height: 20),
                  const LsBanner(
                    tone: LsBannerTone.success,
                    title: 'Password updated.',
                    body: 'Sign in with your new password.',
                  ),
                ],
              ],
            ),
          ),
          bottomDivider: true,
          bottom: state.done
              ? LsButton(label: widget.doneLabel, onPressed: widget.onDone)
              : LsButton(
                  key: const Key('reset_submit'),
                  label: 'Reset password',
                  loadingLabel: 'Resetting…',
                  loading: state.submitting,
                  onPressed: _submit,
                ),
        );
      },
    );
  }
}

/// Six code boxes over one hidden numeric field (supports paste and SMS/
/// email one-time-code autofill).
class _OtpField extends StatefulWidget {
  const _OtpField({
    required this.controller,
    required this.enabled,
    required this.invalid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool invalid;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => Validators.otp(widget.controller.text),
      builder: (field) {
        final text = widget.controller.text;
        final error = field.errorText;
        final borderColor = widget.invalid || error != null
            ? AppColors.error
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('6-digit code', style: LsText.label),
            const SizedBox(height: 6),
            Stack(
              children: [
                // Real input: invisible but focusable and accessible.
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 52,
                    child: TextField(
                      key: const Key('reset_code'),
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      showCursor: false,
                      enableInteractiveSelection: false,
                      onChanged: (v) {
                        setState(() {});
                        field.didChange(v);
                        widget.onChanged(v);
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.enabled ? _focus.requestFocus : null,
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          if (i > 0) const SizedBox(width: LsSpace.xs),
                          Expanded(
                            child: ListenableBuilder(
                              listenable: _focus,
                              builder: (context, _) {
                                final active =
                                    _focus.hasFocus &&
                                    (i == text.length ||
                                        (i == 5 && text.length == 6));
                                return Container(
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      LsRadius.control,
                                    ),
                                    border: Border.all(
                                      color:
                                          borderColor ??
                                          (active
                                              ? AppColors.supportingGreen
                                              : AppColors.border),
                                    ),
                                  ),
                                  child: Text(
                                    i < text.length ? text[i] : '',
                                    style: LsText.screenTitle.copyWith(
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(
                error,
                style: LsText.helper.copyWith(color: AppColors.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
