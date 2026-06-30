import 'package:flutter/material.dart';

/// Rounded search input used by the language and country pickers.
///
/// Shows a clear (✕) button while there is text so users get immediate,
/// obvious feedback that the field is interactive and can be reset with one
/// tap.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.hintText,
    required this.onChanged,
    this.controller,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    // Rebuild so the clear button shows/hides as the text changes.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    // Keep focus so the user can keep typing after clearing.
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: _clear,
              )
            : null,
      ),
    );
  }
}
