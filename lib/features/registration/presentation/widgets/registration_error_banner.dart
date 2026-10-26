import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_components.dart';
import '../cubit/registration_cubit.dart';

/// Banner for a failed `POST /auth/register`. Field-level messages are shown
/// under their fields instead, so the banner only covers the rest.
class RegistrationErrorBanner extends StatelessWidget {
  const RegistrationErrorBanner({
    super.key,
    required this.state,
    this.handledFields = const {},
  });

  final RegistrationState state;

  /// Field names shown inline on the current page.
  final Set<String> handledFields;

  @override
  Widget build(BuildContext context) {
    final f = state.failure;
    if (f == null) return const SizedBox.shrink();

    if (state.duplicate) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: LsBanner(
          tone: LsBannerTone.error,
          title: 'This email is already registered.',
          body: 'Sign in, or reset your password if you forgot it.',
          trailing: Wrap(
            spacing: 8,
            children: [
              LsLinkButton(
                label: 'Sign in',
                onPressed: () => context.go(Routes.login),
              ),
              LsLinkButton(
                label: 'Forgot password',
                onPressed: () => context.go(Routes.forgotPassword),
              ),
            ],
          ),
        ),
      );
    }

    final unhandled = f.fieldErrors.entries
        .where((e) => !handledFields.contains(e.key))
        .map((e) => e.value)
        .toList();
    if (f.fieldErrors.isNotEmpty && unhandled.isEmpty) {
      return const SizedBox.shrink();
    }

    final copy =
        f.kind == FailureKind.validation || f.kind == FailureKind.badRequest
        ? (
            title: 'Check your details.',
            body: unhandled.isNotEmpty
                ? unhandled.join(' ')
                : (f.message ?? 'Some details were not accepted.'),
          )
        : FailureMessages.generic(f);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: LsBanner(
        tone: f.isConnectivity || f.kind == FailureKind.rateLimited
            ? LsBannerTone.warning
            : f.kind == FailureKind.serviceUnavailable ||
                  f.kind == FailureKind.server
            ? LsBannerTone.dark
            : LsBannerTone.error,
        title: copy.title,
        body: copy.body,
      ),
    );
  }
}
