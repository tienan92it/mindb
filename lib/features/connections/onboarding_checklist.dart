import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'connections_screen.dart';
import 'onboarding_status.dart';

class OnboardingChecklist extends StatelessWidget {
  const OnboardingChecklist({
    super.key,
    required this.status,
    this.firstConnectionId,
  });

  final OnboardingStatus status;
  final String? firstConnectionId;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(color: Colors.white, height: 1.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Get started',
            textAlign: TextAlign.center,
            style: mono.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ConnectionsScreen.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '~3 min to first query: connection, API key, then ask.',
            textAlign: TextAlign.center,
            style: mono.copyWith(
              fontSize: 12,
              color: ConnectionsScreen.muted,
            ),
          ),
          const SizedBox(height: 28),
          _StepRow(
            label: '1. Add connection',
            done: status.hasConnection,
            actionLabel: 'Add connection',
            onAction: () => context.push('/connections/new'),
          ),
          const SizedBox(height: 16),
          _StepRow(
            label: '2. LLM API key',
            done: status.hasLlmKey,
            actionLabel: 'Open Settings',
            onAction: () => context.push('/settings'),
          ),
          const SizedBox(height: 16),
          _StepRow(
            label: '3. Ask a question',
            done: false,
            actionLabel: 'Open session',
            enabled: status.canOpenSession && firstConnectionId != null,
            onAction: firstConnectionId == null
                ? null
                : () => context.push('/session/$firstConnectionId'),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.actionLabel,
    this.onAction,
    this.enabled = true,
  });

  final String label;
  final bool done;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? ConnectionsScreen.accent : ConnectionsScreen.muted,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: mono.copyWith(
                  color: done ? ConnectionsScreen.muted : Colors.white,
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              if (!done) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: enabled ? onAction : null,
                  style: TextButton.styleFrom(
                    foregroundColor: ConnectionsScreen.accent,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(actionLabel, style: mono),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
