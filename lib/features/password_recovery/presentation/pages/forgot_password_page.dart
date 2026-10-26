import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../cubit/password_recovery_cubits.dart';

/// 07 Forgot password (ForgotPassword.dc.html).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});
  final String? initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _send() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ForgotPasswordCubit>().submit(_email.text);
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, state) {
        return LsScreen(
          onBack: _back,
          backLabel: 'Back to sign in',
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset your password', style: LsText.pageTitle),
                const SizedBox(height: 6),
                Text(
                  'Enter the email you registered with. We\'ll email you a '
                  '6-digit code.',
                  style: LsText.subtitle,
                ),
                const SizedBox(height: 28),
                LsTextField(
                  fieldKey: const Key('forgot_email'),
                  label: 'Email address',
                  controller: _email,
                  enabled: !state.sending,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  onSubmitted: (_) => _send(),
                ),
                if (state.sent) ...[
                  const SizedBox(height: 20),
                  const LsBanner(
                    tone: LsBannerTone.success,
                    title: 'Check your email.',
                    body:
                        'If an account exists for this email, a 6-digit code '
                        'is on its way. Check spam if it doesn\'t arrive in a '
                        'few minutes.',
                  ),
                ],
                if (state.failure != null) ...[
                  const SizedBox(height: 20),
                  Builder(
                    builder: (_) {
                      final copy = FailureMessages.generic(state.failure!);
                      return LsBanner(
                        tone: LsBannerTone.warning,
                        title: copy.title,
                        body: copy.body,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.sent)
                LsButton(
                  key: const Key('forgot_enter_code'),
                  label: 'Enter code',
                  onPressed: () =>
                      context.push(Routes.resetPasswordFor(_email.text.trim())),
                )
              else
                LsButton(
                  key: const Key('forgot_send'),
                  label: 'Send reset code',
                  loadingLabel: 'Sending…',
                  loading: state.sending,
                  onPressed: _send,
                ),
              const SizedBox(height: 4),
              if (state.sent)
                LsLinkButton(label: 'Send the code again', onPressed: _send)
              else
                LsLinkButton(label: 'Back to sign in', onPressed: _back),
            ],
          ),
        );
      },
    );
  }
}
