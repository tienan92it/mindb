import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/models.dart';
import '../session/session_providers.dart';
import 'connections_providers.dart';
import 'onboarding_checklist.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  static const background = Color(0xFF0D0D0D);
  static const accent = Color(0xFF2DD4BF);
  static const muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsListProvider);
    final readinessAsync = ref.watch(onboardingReadinessProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'mindb',
          style: GoogleFonts.jetBrainsMono(
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: muted),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: accent),
        ),
        error: (error, _) => Center(
          child: Text(
            'Failed to load connections: $error',
            style: GoogleFonts.jetBrainsMono(color: Colors.redAccent),
          ),
        ),
        data: (connections) {
          if (connections.isEmpty) {
            return readinessAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: accent),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load setup status: $error',
                  style: GoogleFonts.jetBrainsMono(color: Colors.redAccent),
                ),
              ),
              data: (status) => OnboardingChecklist(
                status: status,
                firstConnectionId: null,
              ),
            );
          }

          return readinessAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: accent),
            ),
            error: (error, _) => Center(
              child: Text(
                'Failed to load setup status: $error',
                style: GoogleFonts.jetBrainsMono(color: Colors.redAccent),
              ),
            ),
            data: (status) {
              final showKeyBanner =
                  connections.isNotEmpty && !status.hasLlmKey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showKeyBanner)
                    MaterialBanner(
                      backgroundColor: const Color(0xFF141414),
                      content: Text(
                        'Add your LLM API key in Settings to use natural language.',
                        style: GoogleFonts.jetBrainsMono(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.push('/settings'),
                          child: Text(
                            'Open Settings',
                            style: GoogleFonts.jetBrainsMono(color: accent),
                          ),
                        ),
                      ],
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: connections.length,
                      itemBuilder: (context, index) {
                        final connection = connections[index];
                        return _ConnectionTile(connection: connection);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        foregroundColor: background,
        onPressed: () => context.push('/connections/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ConnectionTile extends ConsumerWidget {
  const _ConnectionTile({required this.connection});

  final ConnectionProfile connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 14);

    return Dismissible(
      key: ValueKey(connection.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: ConnectionsScreen.background,
                title: Text('Delete connection?', style: mono),
                content: Text(
                  'Remove "${connection.name}" permanently.',
                  style: mono.copyWith(color: ConnectionsScreen.muted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) {
        ref.read(connectionRepositoryProvider).delete(connection.id);
        ref.read(sessionContextRepositoryProvider).delete(connection.id);
        ref.invalidate(connectionsListProvider);
        ref.invalidate(onboardingReadinessProvider);
      },
      child: ListTile(
        onTap: () => context.push('/session/${connection.id}'),
        title: Text(
          connection.name,
          style: mono.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${connection.username}@${connection.host}:${connection.port}/${connection.database}',
          style: mono.copyWith(color: ConnectionsScreen.muted, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, color: ConnectionsScreen.muted),
          onPressed: () => context.push('/connections/${connection.id}/edit'),
        ),
      ),
    );
  }
}
