import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/llm/llm_provider_models.dart';
import '../../domain/models/models.dart';
import '../connections/connections_screen.dart';

class ProviderModelSelector extends StatelessWidget {
  const ProviderModelSelector({
    super.key,
    required this.provider,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final LlmProviderType provider;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white);
    final options = LlmProviderModels.selectable(provider);
    final dropdownValue = LlmProviderModels.isKnown(provider, value)
        ? value
        : LlmProviderModels.recommended(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${provider.label} model',
          style: mono.copyWith(color: ConnectionsScreen.muted),
        ),
        DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          dropdownColor: const Color(0xFF141414),
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.label, style: mono),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              hint!,
              style: mono.copyWith(color: ConnectionsScreen.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
