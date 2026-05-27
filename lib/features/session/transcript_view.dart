import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/models.dart';
import '../connections/connections_screen.dart';
import 'table_result_block.dart';

class TranscriptView extends StatefulWidget {
  const TranscriptView({super.key, required this.lines});

  final List<TranscriptLine> lines;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final _scrollController = ScrollController();
  var _hasScrolledOnce = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TranscriptView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length) {
      _scrollToBottom(animated: _hasScrolledOnce);
      _hasScrolledOnce = true;
    }
  }

  void _scrollToBottom({required bool animated}) {
    void scroll() {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scroll();
      // Second frame: ListView may extend maxScrollExtent after first layout pass.
      WidgetsBinding.instance.addPostFrameCallback((_) => scroll());
    });
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.5);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: widget.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lines[index];
        return switch (line) {
          UserLine(:final text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '> $text',
                style: mono.copyWith(color: ConnectionsScreen.accent),
              ),
            ),
          AssistantLine(:final text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '• $text',
                style: mono.copyWith(color: Colors.white),
              ),
            ),
          SystemLine(:final text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                text,
                style: mono.copyWith(
                  color: ConnectionsScreen.muted,
                  fontSize: 12,
                ),
              ),
            ),
          ErrorLine(:final message, :final action) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '! $message',
                    style: mono.copyWith(color: Colors.redAccent),
                  ),
                  if (action == SessionRecoveryAction.settings)
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Open Settings',
                        style: mono.copyWith(color: ConnectionsScreen.accent),
                      ),
                    ),
                ],
              ),
            ),
          ResultLine(:final result) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TableResultBlock(result: result),
            ),
        };
      },
    );
  }
}
