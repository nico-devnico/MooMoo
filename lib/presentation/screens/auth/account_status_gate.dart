import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/providers/account_appeal_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/profile_provider.dart';
import '../../../l10n/app_localizations.dart';

/// A banned account the user has to be told about.
class SuspendedAccount {
  const SuspendedAccount({this.reason = '', this.email});

  final String reason;

  /// Address the administrator answers to; asked for when unknown.
  final String? email;
}

class SuspensionNotice extends Notifier<SuspendedAccount?> {
  @override
  SuspendedAccount? build() => null;

  void show({String? reason, String? email}) =>
      state = SuspendedAccount(reason: reason?.trim() ?? '', email: email?.trim());

  void dismiss() => state = null;
}

final suspensionNoticeProvider =
    NotifierProvider<SuspensionNotice, SuspendedAccount?>(SuspensionNotice.new);

/// Signs a banned account out the moment its profile says so (the profile is
/// a realtime stream), then shows a window explaining it, from which the user
/// can write to the administrators.
///
/// The server already refuses the account (Auth ban, revoked sessions, RLS,
/// API): this is what makes the lock visible without waiting for the access
/// token to expire. The login screen also opens the window when a banned
/// account tries to sign in.
class AccountStatusGate extends ConsumerStatefulWidget {
  const AccountStatusGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AccountStatusGate> createState() => _AccountStatusGateState();
}

class _AccountStatusGateState extends ConsumerState<AccountStatusGate> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<UserProfile?>>(
      userProfileProvider,
      (_, next) {
        final profile = next.value;
        if (profile == null || profile.status != 'suspended') return;
        // Providers must not be modified while the widget tree is building.
        Future.microtask(() {
          if (!mounted) return;
          ref.read(suspensionNoticeProvider.notifier).show(
                reason: profile.suspendedReason,
                email: profile.email ?? ref.read(currentUserProvider)?.email,
              );
          ref.read(authRepositoryProvider).signOut();
        });
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(suspensionNoticeProvider);
    return Stack(
      children: [
        widget.child,
        if (notice != null) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          // The gate sits above the router's Navigator: text fields need their
          // own Overlay for selection handles and the magnifier.
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => _BannedWindow(
                  key: ObjectKey(notice),
                  account: notice,
                  onClose: () => ref.read(suspensionNoticeProvider.notifier).dismiss(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

enum _Step { info, form, sent }

class _BannedWindow extends ConsumerStatefulWidget {
  const _BannedWindow({super.key, required this.account, required this.onClose});

  final SuspendedAccount account;
  final VoidCallback onClose;

  @override
  ConsumerState<_BannedWindow> createState() => _BannedWindowState();
}

class _BannedWindowState extends ConsumerState<_BannedWindow> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.account.email ?? '');
  final _messageController = TextEditingController();
  _Step _step = _Step.info;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      await ref.read(accountAppealRepositoryProvider).submit(
            email: _emailController.text,
            message: _messageController.text,
          );
      if (mounted) setState(() => _step = _Step.sent);
    } catch (e) {
      debugPrint('Account appeal: $e');
      if (mounted) setState(() => _error = l10n.appealSendFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 12,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: switch (_step) {
                      _Step.info => _buildInfo(context),
                      _Step.form => _buildForm(context),
                      _Step.sent => _buildSent(context),
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(IconData icon, Color color, String title) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: AppSpacing.m),
        Semantics(
          header: true,
          child: Text(title, textAlign: TextAlign.center, style: AppTextStyles.h3),
        ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = widget.account.reason;
    return Column(
      key: const ValueKey(_Step.info),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(AppIcons.locked, AppColors.error, l10n.accountSuspendedTitle),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.accountSuspendedMessage,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)),
        ),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.accountSuspendedReason(reason),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          autofocus: true,
          onPressed: () => setState(() => _step = _Step.form),
          icon: const Icon(AppIcons.mail),
          label: Text(l10n.appealContactAdmin),
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(onPressed: widget.onClose, child: Text(l10n.accountSuspendedAck)),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey(_Step.form),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(AppIcons.mail, AppColors.primary, l10n.appealContactAdmin),
          const SizedBox(height: AppSpacing.s),
          Text(
            l10n.appealFormIntro,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: AppSpacing.l),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            enabled: !_sending,
            decoration: InputDecoration(
              labelText: l10n.appealEmailLabel,
              prefixIcon: const Icon(AppIcons.mail),
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return l10n.requiredField;
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _messageController,
            autofocus: true,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.appealMessageLabel,
              hintText: l10n.appealMessageHint,
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                (value?.trim().length ?? 0) < 10 ? l10n.appealMessageTooShort : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.send),
            label: Text(l10n.appealSend),
          ),
          const SizedBox(height: AppSpacing.s),
          TextButton(
            onPressed: _sending ? null : () => setState(() => _step = _Step.info),
            child: Text(l10n.appealBack),
          ),
        ],
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey(_Step.sent),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(AppIcons.success, AppColors.success, l10n.appealSentTitle),
        const SizedBox(height: AppSpacing.m),
        Text(
          l10n.appealSentMessage(_emailController.text.trim()),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          autofocus: true,
          onPressed: widget.onClose,
          child: Text(l10n.accountSuspendedAck),
        ),
      ],
    );
  }
}
