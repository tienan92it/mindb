import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/models.dart';
import 'connections_providers.dart';
import 'connections_screen.dart';

class ConnectionFormScreen extends ConsumerStatefulWidget {
  const ConnectionFormScreen({super.key, this.connectionId});

  final String? connectionId;

  @override
  ConsumerState<ConnectionFormScreen> createState() =>
      _ConnectionFormScreenState();
}

class _ConnectionFormScreenState extends ConsumerState<ConnectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _databaseController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _useSsl = false;
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testMessage;
  ConnectionProfile? _existing;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hostController = TextEditingController(text: 'localhost');
    _portController = TextEditingController(text: '5432');
    _databaseController = TextEditingController(text: 'postgres');
    _usernameController = TextEditingController(text: 'postgres');
    _passwordController = TextEditingController();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final id = widget.connectionId;
    if (id == null) return;

    final repo = ref.read(connectionRepositoryProvider);
    final profile = await repo.getById(id);
    if (profile == null || !mounted) return;

    final password = await repo.readPassword(id);
    setState(() {
      _existing = profile;
      _nameController.text = profile.name;
      _hostController.text = profile.host;
      _portController.text = profile.port.toString();
      _databaseController.text = profile.database;
      _usernameController.text = profile.username;
      _passwordController.text = password ?? '';
      _useSsl = profile.useSsl;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ConnectionProfile _buildProfile() {
    if (_existing != null) {
      return _existing!.copyWith(
        name: _nameController.text.trim(),
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        useSsl: _useSsl,
      );
    }

    return ConnectionProfile.create(
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      database: _databaseController.text.trim(),
      username: _usernameController.text.trim(),
      useSsl: _useSsl,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testMessage = null;
    });

    try {
      final client = ref.read(postgresClientProvider);
      final profile = _buildProfile();
      await client.testConnection(profile, _passwordController.text);
      setState(() => _testMessage = 'Connection successful');
    } catch (e) {
      setState(() => _testMessage = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final profile = _buildProfile();
      await ref.read(connectionRepositoryProvider).save(
            profile,
            password: _passwordController.text,
          );
      ref.invalidate(connectionsListProvider);
      ref.invalidate(onboardingReadinessProvider);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white);

    return Scaffold(
      backgroundColor: ConnectionsScreen.background,
      appBar: AppBar(
        backgroundColor: ConnectionsScreen.background,
        title: Text(
          widget.connectionId == null ? 'New connection' : 'Edit connection',
          style: mono,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field('Name', _nameController, mono, required: true),
            _field('Host', _hostController, mono, required: true),
            _field('Port', _portController, mono,
                required: true, keyboardType: TextInputType.number),
            _field('Database', _databaseController, mono, required: true),
            _field('Username', _usernameController, mono, required: true),
            _field('Password', _passwordController, mono, obscure: true),
            SwitchListTile(
              title: Text('Use SSL', style: mono),
              value: _useSsl,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return ConnectionsScreen.accent;
                }
                return null;
              }),
              onChanged: (value) => setState(() => _useSsl = value),
            ),
            if (_testMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _testMessage!,
                  style: mono.copyWith(
                    color: _testMessage!.startsWith('Connection successful')
                        ? ConnectionsScreen.accent
                        : Colors.redAccent,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    child: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ConnectionsScreen.accent,
                      foregroundColor: ConnectionsScreen.background,
                    ),
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    TextStyle mono, {
    bool required = false,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: mono,
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? '$label required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: mono.copyWith(color: ConnectionsScreen.muted),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: ConnectionsScreen.muted),
          ),
        ),
      ),
    );
  }
}
