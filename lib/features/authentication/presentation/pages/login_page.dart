import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../cubit/login_cubit.dart';

/// 02 Sign in (Login.dc.html).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginCubit>().submit(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        final cubit = context.read<LoginCubit>();
        return LsScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.welcome),
          body: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sign in', style: LsText.authTitle),
                  const SizedBox(height: 6),
                  Text(
                    'Use your LungSense Pro account.',
                    style: LsText.subtitle,
                  ),
                  const SizedBox(height: LsSpace.lg),
                  const _GoogleButton(),
                  const SizedBox(height: 20),
                  const _OrDivider(),
                  if (state.error != null) ...[
                    const SizedBox(height: LsSpace.md),
                    _ErrorBanner(
                      state: state,
                      onResend: () => cubit.resendConfirmation(_email.text),
                    ),
                  ],
                  const SizedBox(height: LsSpace.md),
                  LsTextField(
                    fieldKey: const Key('login_email'),
                    label: 'Email address',
                    controller: _email,
                    enabled: !state.submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onChanged: (_) => cubit.clearError(),
                  ),
                  const SizedBox(height: LsSpace.md),
                  LsTextField(
                    fieldKey: const Key('login_password'),
                    label: 'Password',
                    controller: _password,
                    obscure: true,
                    enabled: !state.submitting,
                    highlightError: state.error == LoginError.wrongCredentials,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.requiredPassword,
                    onChanged: (_) => cubit.clearError(),
                    onSubmitted: (_) => _submit(),
                    trailingLabel: TextButton(
                      onPressed: state.submitting
                          ? null
                          : () => context.push(Routes.forgotPassword),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.supportingGreen,
                        minimumSize: const Size(LsSize.minTouch, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: LsText.label,
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LsButton(
                key: const Key('login_submit'),
                label: 'Sign in',
                loadingLabel: 'Signing in…',
                loading: state.submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'New here?',
                    style: LsText.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: state.submitting
                        ? null
                        : () => context.push(Routes.signUp),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.supportingGreen,
                      minimumSize: const Size(LsSize.minTouch, LsSize.minTouch),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: LsText.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.state, required this.onResend});
  final LoginState state;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    switch (state.error!) {
      case LoginError.wrongCredentials:
        return const LsBanner(
          tone: LsBannerTone.error,
          title: 'Wrong email or password.',
          body: 'Check both and try again.',
        );
      case LoginError.emailNotConfirmed:
        final (label, loading) = switch (state.resend) {
          ResendStatus.sending => ('Sending…', true),
          ResendStatus.sent => ('Request received', true),
          ResendStatus.failed => ('Try sending again', false),
          ResendStatus.idle => ('Resend confirmation email', false),
        };
        return LsBanner(
          tone: LsBannerTone.warning,
          title: 'Confirm your email first.',
          body: state.resend == ResendStatus.sent
              ? 'If the address is registered and unconfirmed, a new link '
                    'is on its way. Check your spam folder too.'
              : 'Open the link we sent to your email address.',
          actionLabel: label,
          actionLoading: loading,
          onAction: onResend,
        );
      case LoginError.tooManyAttempts:
        return const LsBanner(
          tone: LsBannerTone.warning,
          title: 'Too many attempts.',
          body: 'Please wait a few minutes and try again.',
        );
      case LoginError.serviceUnavailable:
        return const LsBanner(
          tone: LsBannerTone.dark,
          title: 'Server-side problem.',
          body: 'Sign-in is temporarily unavailable. Please try again later.',
        );
      case LoginError.network:
        return const LsBanner(
          tone: LsBannerTone.warning,
          title: 'Can\'t reach LungSense Pro.',
          body: 'Check your connection and try again.',
        );
      case LoginError.unexpected:
        return LsBanner(
          tone: LsBannerTone.error,
          title: 'Sign-in failed.',
          body:
              state.serverMessage ?? 'Something went wrong. Please try again.',
        );
    }
  }
}

/// Google sign-in is designed but not enabled on the server yet, so the
/// entry point is shown disabled and labelled as unavailable.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    const enabled = ApiConfig.googleSignInEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LsButton(
          label: 'Continue with Google',
          variant: LsButtonVariant.secondary,
          // Wired in milestone M6 once the backend enables Google OAuth.
          onPressed: null,
          icon: Text(
            'G',
            style: LsText.button.copyWith(
              color: enabled ? AppColors.text : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!enabled) ...[
          const SizedBox(height: 6),
          Text(
            'Google sign-in isn\'t available yet.',
            textAlign: TextAlign.center,
            style: LsText.helper,
          ),
        ],
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: AppColors.border, height: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: LsSpace.sm),
        child: Text('or with email', style: LsText.helper),
      ),
      const Expanded(child: Divider(color: AppColors.border, height: 1)),
    ],
  );
}
