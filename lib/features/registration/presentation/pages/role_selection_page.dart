import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/ls_banner.dart';
import '../../../../core/widgets/ls_button.dart';
import '../../../../core/widgets/ls_screen.dart';
import '../../../../core/widgets/ls_text_field.dart';
import '../../../authentication/domain/entities/registration.dart';
import '../../../authentication/presentation/cubit/session_cubit.dart';
import '../cubit/account_type_cubit.dart';
import '../widgets/doctor_profile_form.dart';
import 'role_choice_page.dart';

/// First-time Google user (role `new`) picks patient or doctor. Reached only
/// after the backend reports role `new`; Google sign-in itself stays disabled
/// in this build (see KNOWN_ISSUES).
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key, this.initialName});
  final String? initialName;

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  final _doctor = DoctorProfileFormController();

  @override
  void dispose() {
    _name.dispose();
    _doctor.dispose();
    super.dispose();
  }

  void _submit(AccountTypeState state) {
    FocusScope.of(context).unfocus();
    final nameOk = _formKey.currentState?.validate() ?? false;
    DoctorProfileInput? profile;
    if (state.accountType == AccountType.doctor) {
      profile = _doctor.validateAndBuild();
      if (profile == null) return;
    }
    if (!nameOk) return;
    context.read<AccountTypeCubit>().submit(
      fullName: _name.text,
      doctorProfile: profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountTypeCubit, AccountTypeState>(
      builder: (context, state) {
        final cubit = context.read<AccountTypeCubit>();
        final f = state.failure;
        return LsScreen(
          onBack: () => context.read<SessionCubit>().signOut(),
          backLabel: 'Sign out',
          bottomDivider: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RoleChoiceBody(
                selected: state.accountType,
                onSelect: state.submitting ? (_) {} : cubit.chooseType,
              ),
              if (f != null && (f.fieldErrors.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: LsBanner(
                    tone: f.isConnectivity
                        ? LsBannerTone.warning
                        : LsBannerTone.error,
                    title: f.kind == FailureKind.validation
                        ? 'Check your details.'
                        : FailureMessages.generic(f).title,
                    body: f.kind == FailureKind.validation
                        ? (f.message ?? 'Some details were not accepted.')
                        : FailureMessages.generic(f).body,
                  ),
                ),
              if (state.accountType != null) ...[
                const SizedBox(height: LsSpace.lg),
                Form(
                  key: _formKey,
                  child: LsTextField(
                    fieldKey: const Key('select_name'),
                    label: 'Full name',
                    controller: _name,
                    enabled: !state.submitting,
                    autofillHints: const [AutofillHints.name],
                    errorText: state.fieldErrors['full_name'],
                    validator: Validators.required('Enter your full name.'),
                    onChanged: (_) => cubit.clearError(),
                  ),
                ),
              ],
              if (state.accountType == AccountType.doctor) ...[
                const SizedBox(height: LsSpace.md),
                DoctorProfileForm(
                  controller: _doctor,
                  enabled: !state.submitting,
                  fieldErrors: state.fieldErrors,
                  showCredentialNotes: false,
                  onChanged: cubit.clearError,
                ),
              ],
            ],
          ),
          bottom: LsButton(
            key: const Key('select_continue'),
            label: 'Continue',
            loadingLabel: 'Saving…',
            loading: state.submitting,
            onPressed: state.accountType == null ? null : () => _submit(state),
          ),
        );
      },
    );
  }
}
