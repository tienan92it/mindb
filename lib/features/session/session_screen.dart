import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../connections/connections_screen.dart';
import 'llm_status_bar.dart';
import 'session_error_mapper.dart';
import 'session_providers.dart';
import 'sql_input_bar.dart';
import 'transcript_view.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.connectionId});

  final String connectionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider(widget.connectionId));
    final controller =
        ref.read(sessionControllerProvider(widget.connectionId).notifier);
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white);

    ref.listen(sessionControllerProvider(widget.connectionId), (previous, next) {
      final pending = next.pendingConfirmation;
      if (pending != null &&
          previous?.pendingConfirmation?.sql != pending.sql) {
        _showConfirmationSheet(context, controller, pending);
      }
    });

    return Scaffold(
      backgroundColor: ConnectionsScreen.background,
      appBar: AppBar(
        backgroundColor: ConnectionsScreen.background,
        title: Text(
          state.connectionName ?? 'Session',
          style: mono,
        ),
        actions: [
          IconButton(
            tooltip: 'Clear session',
            onPressed: state.isBusy
                ? null
                : () => controller.clearSessionContext(),
            icon: Icon(Icons.delete_sweep_outlined, color: mono.color?.withValues(alpha: 0.8)),
          ),
          if (state.isBusy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ConnectionsScreen.accent,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!state.isConnected && state.error != null)
            _ConnectErrorBanner(
              message: state.error!,
              action: state.errorAction,
              connectionId: widget.connectionId,
            ),
          Expanded(child: TranscriptView(lines: state.lines)),
          if (state.llmProvider != null && state.llmModel != null)
            LlmStatusBar(
              provider: state.llmProvider!,
              model: state.llmModel!,
            ),
          SqlInputBar(
            enabled: state.isConnected && !state.isBusy,
            onSubmit: controller.submitPrompt,
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationSheet(
    BuildContext context,
    SessionController controller,
    PendingConfirmation pending,
  ) async {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 13);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm ${pending.classification.name} query',
                style: mono.copyWith(
                  color: ConnectionsScreen.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pending.sql,
                style: mono.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        controller.resolveConfirmation(false);
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ConnectionsScreen.accent,
                        foregroundColor: ConnectionsScreen.background,
                      ),
                      onPressed: () {
                        controller.resolveConfirmation(true);
                        Navigator.pop(context);
                      },
                      child: const Text('Run'),
                    ),
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

class _ConnectErrorBanner extends StatelessWidget {
  const _ConnectErrorBanner({
    required this.message,
    required this.action,
    required this.connectionId,
  });

  final String message;
  final SessionRecoveryAction? action;
  final String connectionId;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 13, color: Colors.white70);

    String? buttonLabel;
    VoidCallback? onPressed;
    switch (action) {
      case SessionRecoveryAction.settings:
        buttonLabel = 'Open Settings';
        onPressed = () => context.push('/settings');
      case SessionRecoveryAction.editConnection:
        buttonLabel = 'Edit connection';
        onPressed = () => context.push('/connections/$connectionId/edit');
      case SessionRecoveryAction.none:
      case null:
        break;
    }

    return Material(
      color: const Color(0xFF1A1010),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: mono)),
            if (buttonLabel != null && onPressed != null)
              TextButton(
                onPressed: onPressed,
                child: Text(
                  buttonLabel,
                  style: mono.copyWith(color: ConnectionsScreen.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
