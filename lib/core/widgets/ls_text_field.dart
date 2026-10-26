import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// Labelled input from Components.dc.html / Login.dc.html: label above,
/// 48px field, 1px border, green focus edge, error text below.
/// With [obscure] it adds a 44px show/hide toggle.
class LsTextField extends StatefulWidget {
  const LsTextField({
    super.key,
    required this.label,
    this.controller,
    this.trailingLabel,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscure = false,
    this.highlightError = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;

  /// Widget shown at the end of the label row (e.g. "Forgot password?").
  final Widget? trailingLabel;
  final String? hint;
  final String? helperText;

  /// Server-side error to show under the field.
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscure;

  /// Red outline without a message (e.g. wrong password, Login.dc.html).
  final bool highlightError;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final Key? fieldKey;

  @override
  State<LsTextField> createState() => _LsTextFieldState();
}

class _LsTextFieldState extends State<LsTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(widget.label, style: LsText.label)),
            ?widget.trailingLabel,
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _hidden,
          enableSuggestions: !widget.obscure,
          autocorrect: false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: LsText.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            helperMaxLines: 3,
            errorText: widget.errorText,
            errorMaxLines: 3,
            enabledBorder: widget.highlightError
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LsRadius.control),
                    borderSide: const BorderSide(color: AppColors.error),
                  )
                : null,
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
