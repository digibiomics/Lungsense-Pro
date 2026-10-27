import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

/// 48px search input with a leading icon (Patients, AdminUsers). Calls
/// [onChanged] after the user stops typing for [debounce].
class LsSearchField extends StatefulWidget {
  const LsSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 350),
    this.fieldKey,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final Duration debounce;
  final Key? fieldKey;

  @override
  State<LsSearchField> createState() => _LsSearchFieldState();
}

class _LsSearchFieldState extends State<LsSearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(v));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: widget.fieldKey,
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) {
        _timer?.cancel();
        widget.onChanged(v);
      },
      style: LsText.body,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textSecondary,
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
      ),
    );
  }
}
