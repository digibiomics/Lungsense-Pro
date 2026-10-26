import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_components.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../../../authentication/presentation/widgets/google_sign_in_button.dart';
import '../cubit/registration_cubit.dart';

/// 03 Doctor or patient (RoleChoice.dc.html).
class RoleChoicePage extends StatelessWidget {
  const RoleChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationCubit, RegistrationState>(
      builder: (context, state) {
        final cubit = context.read<RegistrationCubit>();
        return LsScreen(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(Routes.welcome),
          headerTrailing: state.accountType == null
              ? null
              : LsStepLabel('Step 1 of ${state.totalSteps}'),
          body: RoleChoiceBody(
            selected: state.accountType,
            onSelect: cubit.chooseType,
          ),
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LsButton(
                key: const Key('role_continue'),
                label: 'Continue with email',
                onPressed: state.accountType == null
                    ? null
                    : () => context.push(Routes.signUpAccount),
              ),
              const SizedBox(height: 10),
              const GoogleSignInButton(),
            ],
          ),
        );
      },
    );
  }
}

/// Title + role cards; shared with the Google account-type screen.
class RoleChoiceBody extends StatelessWidget {
  const RoleChoiceBody({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AccountType? selected;
  final ValueChanged<AccountType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Who is this account for?', style: LsText.authTitle),
        const SizedBox(height: 6),
        Text(
          'This sets what you can do in the app. It can\'t be changed later.',
          style: LsText.subtitle,
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'Account type',
          child: Column(
            children: [
              LsChoiceCard(
                key: const Key('role_doctor'),
                selected: selected == AccountType.doctor,
                onTap: () => onSelect(AccountType.doctor),
                icon: Icons.medical_services_outlined,
                iconTint: LsTint.featureSecondary,
                title: 'I\'m a doctor',
                body: 'Register patients and collect recordings during visits.',
                badge: const LsStatusPill(
                  label: 'Needs admin approval',
                  tone: LsPillTone.pending,
                ),
              ),
              const SizedBox(height: LsSpace.sm),
              LsChoiceCard(
                key: const Key('role_patient'),
                selected: selected == AccountType.patient,
                onTap: () => onSelect(AccountType.patient),
                icon: Icons.person_outline,
                iconTint: LsTint.featureAccent,
                title: 'I\'m a patient',
                body: 'Record your own cough, breathing and symptoms.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
