import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../connections/connections_screen.dart';

class SqlInputBar extends StatefulWidget {
  const SqlInputBar({
    super.key,
    required this.onSubmit,
    this.enabled = true,
  });

  final ValueChanged<String> onSubmit;
  final bool enabled;

  @override
  State<SqlInputBar> createState() => _SqlInputBarState();
}

class _SqlInputBarState extends State<SqlInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white);

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              style: mono,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Ask or sql: SELECT ...',
                hintStyle: mono.copyWith(color: ConnectionsScreen.muted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.enabled ? _submit : null,
            icon: Icon(
              Icons.arrow_upward,
              color: widget.enabled
                  ? ConnectionsScreen.accent
                  : ConnectionsScreen.muted,
            ),
          ),
        ],
      ),
    );
  }
}
