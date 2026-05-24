import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/llm/llm_provider_models.dart';
import '../../domain/models/models.dart';
import '../connections/connections_providers.dart';
import '../connections/connections_screen.dart';
import '../session/session_providers.dart';
import 'provider_model_selector.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _openAiKeyController = TextEditingController();
  final _anthropicKeyController = TextEditingController();
  final _kimiKeyController = TextEditingController();
  LlmProviderType _provider = LlmProviderType.openai;
  late Map<LlmProviderType, String> _models;
  bool _readOnly = false;
  int _maxRows = 200;
  int _timeout = 30;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _models = {
      for (final provider in LlmProviderType.values)
        provider: LlmProviderModels.recommended(provider),
    };
  }

  @override
  void dispose() {
    _openAiKeyController.dispose();
    _anthropicKeyController.dispose();
    _kimiKeyController.dispose();
    super.dispose();
  }

  String _modelFor(LlmProviderType provider) => _models[provider]!;

  void _setModelFor(LlmProviderType provider, String model) {
    _models[provider] = model;
  }

  Future<void> _load() async {
    if (_loaded) return;
    final repo = await ref.read(settingsRepositoryProvider.future);
    final settings = repo.load();
    final store = ref.read(credentialStoreProvider);
    final openAiKey = await store.readLlmApiKey(LlmProviderType.openai);
    final anthropicKey = await store.readLlmApiKey(LlmProviderType.anthropic);
    final kimiKey = await store.readLlmApiKey(LlmProviderType.kimi);

    if (!mounted) return;
    setState(() {
      _provider = settings.llmProvider;
      _models = repo.loadAllModels();
      _readOnly = settings.readOnlyMode;
      _maxRows = settings.maxRows;
      _timeout = settings.queryTimeoutSeconds;
      _openAiKeyController.text = openAiKey ?? '';
      _anthropicKeyController.text = anthropicKey ?? '';
      _kimiKeyController.text = kimiKey ?? '';
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      final store = ref.read(credentialStoreProvider);

      await repo.save(
        AppSettings(
          llmProvider: _provider,
          llmModel: _modelFor(_provider),
          readOnlyMode: _readOnly,
          maxRows: _maxRows,
          queryTimeoutSeconds: _timeout,
        ),
        modelsByProvider: _models,
      );

      if (_openAiKeyController.text.isNotEmpty) {
        await store.saveLlmApiKey(
          LlmProviderType.openai,
          _openAiKeyController.text.trim(),
        );
      }
      if (_anthropicKeyController.text.isNotEmpty) {
        await store.saveLlmApiKey(
          LlmProviderType.anthropic,
          _anthropicKeyController.text.trim(),
        );
      }
      if (_kimiKeyController.text.isNotEmpty) {
        await store.saveLlmApiKey(
          LlmProviderType.kimi,
          _kimiKeyController.text.trim(),
        );
      }

      ref.invalidate(appSettingsProvider);
      ref.invalidate(onboardingReadinessProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _load();
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white);

    return Scaffold(
      backgroundColor: ConnectionsScreen.background,
      appBar: AppBar(
        backgroundColor: ConnectionsScreen.background,
        title: Text('Settings', style: mono),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('LLM Provider', style: mono.copyWith(color: ConnectionsScreen.muted)),
          DropdownButton<LlmProviderType>(
            value: _provider,
            dropdownColor: const Color(0xFF141414),
            items: LlmProviderType.values
                .map(
                  (provider) => DropdownMenuItem(
                    value: provider,
                    child: Text(provider.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _provider = value);
            },
          ),
          const SizedBox(height: 12),
          if (_provider == LlmProviderType.openai)
            ProviderModelSelector(
              provider: LlmProviderType.openai,
              value: _modelFor(LlmProviderType.openai),
              onChanged: (model) =>
                  setState(() => _setModelFor(LlmProviderType.openai, model)),
            )
          else if (_provider == LlmProviderType.anthropic)
            ProviderModelSelector(
              provider: LlmProviderType.anthropic,
              value: _modelFor(LlmProviderType.anthropic),
              onChanged: (model) => setState(
                () => _setModelFor(LlmProviderType.anthropic, model),
              ),
            )
          else
            ProviderModelSelector(
              provider: LlmProviderType.kimi,
              value: _modelFor(LlmProviderType.kimi),
              onChanged: (model) =>
                  setState(() => _setModelFor(LlmProviderType.kimi, model)),
              hint: 'Start with moonshot-v1-8k if K2 models return 404.',
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _openAiKeyController,
            style: mono,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'OpenAI API Key'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _anthropicKeyController,
            style: mono,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Anthropic API Key'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kimiKeyController,
            style: mono,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Kimi API Key'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Read-only mode', style: mono),
            subtitle: Text(
              'Block write and destructive SQL',
              style: mono.copyWith(color: ConnectionsScreen.muted, fontSize: 12),
            ),
            value: _readOnly,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return ConnectionsScreen.accent;
              }
              return null;
            }),
            onChanged: (value) => setState(() => _readOnly = value),
          ),
          ListTile(
            title: Text('Max rows', style: mono),
            subtitle: Slider(
              value: _maxRows.toDouble(),
              min: 50,
              max: 1000,
              divisions: 19,
              label: _maxRows.toString(),
              activeColor: ConnectionsScreen.accent,
              onChanged: (value) => setState(() => _maxRows = value.round()),
            ),
          ),
          ListTile(
            title: Text('Query timeout (seconds)', style: mono),
            subtitle: Slider(
              value: _timeout.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: _timeout.toString(),
              activeColor: ConnectionsScreen.accent,
              onChanged: (value) => setState(() => _timeout = value.round()),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ConnectionsScreen.accent,
              foregroundColor: ConnectionsScreen.background,
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save settings'),
          ),
        ],
      ),
    );
  }
}
