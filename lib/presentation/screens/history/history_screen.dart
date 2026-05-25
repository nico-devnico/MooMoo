import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/session_provider.dart';
import '../../widgets/app_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return const Center(child: Text('Aucun historique de traduction'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.l),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final session = history[index];
                  return _HistoryTile(session: session);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Erreur : $e')),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final entries = session['translation_entries'] as List?;
    final lastText = entries != null && entries.isNotEmpty ? entries.last['translated_text'] : '...';
    final date = DateTime.parse(session['created_at']);
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final isSignToText = session['session_type'] == 'sign_to_text';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSignToText ? Icons.camera_alt_outlined : Icons.keyboard_outlined,
              color: AppColors.primary,
            ),
          ),
          title: Text(lastText, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$formattedDate • ${isSignToText ? 'Signe → Texte' : 'Texte → Signe'}'),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {},
        ),
      ),
    );
  }
}
