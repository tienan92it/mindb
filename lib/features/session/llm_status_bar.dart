import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/models.dart';
import '../connections/connections_screen.dart';

class LlmStatusBar extends StatelessWidget {
  const LlmStatusBar({
    super.key,
    required this.provider,
    required this.model,
  });

  final LlmProviderType provider;
  final String model;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: ConnectionsScreen.muted,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 14,
            color: ConnectionsScreen.accent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Text('LLM', style: mono.copyWith(color: ConnectionsScreen.accent)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${provider.label} · $model',
              style: mono,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
