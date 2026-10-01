import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/constants/character_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/providers/character_provider.dart';
import '../../../domain/providers/error_text.dart';
import '../../../domain/providers/three_d_settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../skeletons.dart';

/// Mixamo avatar driven by Holistic landmark frames (text→sign compose).
class RiggedSignAvatar extends ConsumerStatefulWidget {
  const RiggedSignAvatar({
    super.key,
    this.rigPayload,
    this.note,
  });

  /// `{fps, frames:[{pose,leftHand,rightHand}]}` from LandmarkComposeResult.toRigPayload.
  final Map<String, dynamic>? rigPayload;
  final String? note;

  @override
  ConsumerState<RiggedSignAvatar> createState() => _RiggedSignAvatarState();
}

class _RiggedSignAvatarState extends ConsumerState<RiggedSignAvatar> {
  /// WebViewController from model_viewer_plus (avoid direct webview_flutter dep).
  dynamic _controller;
  String? _rigJs;
  String? _lastSentHash;
  String _status = 'boot';

  @override
  void initState() {
    super.initState();
    unawaited(_loadJs());
  }

  Future<void> _loadJs() async {
    try {
      final js = await rootBundle.loadString('assets/js/moomoo_sign_rig.js');
      if (!mounted) return;
      setState(() => _rigJs = js);
    } catch (e) {
      debugPrint('MooMooSignRig: failed to load JS: $e');
    }
  }

  @override
  void didUpdateWidget(covariant RiggedSignAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePayload(oldWidget.rigPayload, widget.rigPayload)) {
      unawaited(_pushPayload(force: true));
    }
  }

  bool _samePayload(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    return jsonEncode(a) == jsonEncode(b);
  }

  /// Always call JS `play`/`stop` — the script queues until bones are ready.
  Future<void> _pushPayload({bool force = false}) async {
    final controller = _controller;
    if (controller == null) return;

    final payload = widget.rigPayload;
    final frames = payload?['frames'];
    if (payload == null || frames is! List || frames.isEmpty) {
      try {
        await controller.runJavaScript(
          'window.MooMooSignRig && window.MooMooSignRig.stop(true);',
        );
      } catch (e) {
        debugPrint('MooMooSignRig stop failed: $e');
      }
      _lastSentHash = null;
      return;
    }

    final encoded = jsonEncode(payload);
    final hash = encoded.hashCode.toString();
    if (!force && hash == _lastSentHash) return;
    _lastSentHash = hash;

    try {
      await controller.runJavaScript(
        'window.MooMooSignRig && window.MooMooSignRig.play($encoded);',
      );
      debugPrint('MooMooSignRig: play sent (${frames.length} frames)');
    } catch (e) {
      debugPrint('MooMooSignRig play failed: $e');
      // Retry shortly — WebView may not have evaluated relatedJs yet.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      try {
        await controller.runJavaScript(
          'window.MooMooSignRig && window.MooMooSignRig.play($encoded);',
        );
      } catch (e2) {
        debugPrint('MooMooSignRig play retry failed: $e2');
      }
    }
  }

  void _onReady(dynamic message) {
    final text = '${message.message}';
    debugPrint('MooMooSignRig: $text');
    if (mounted) setState(() => _status = text);
    if (text.startsWith('ready:') || text.startsWith('play:queued')) {
      unawaited(_pushPayload(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const loading = Skeleton(
      child: SkeletonBlock(height: double.infinity, radius: AppRadius.l),
    );

    Widget failure(Object e) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Text(
              ref.userErrorText(e, l10n),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        );

    if (_rigJs == null) return loading;

    return ref.watch(threeDSettingsProvider).when(
          loading: () => loading,
          error: (e, _) => failure(e),
          data: (settings) {
            final characterId = settings['selectedCharacterId'] as String? ??
                CharacterConstants.defaultCharacterId;
            return ref.watch(characterByIdProvider(characterId)).when(
                  loading: () => loading,
                  error: (e, _) => failure(e),
                  data: (character) {
                    if (character == null) {
                      return Center(child: Text(l10n.translCharacterNotFound));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ModelViewer(
                            key: ValueKey(
                              'rigged_${character.id}_'
                              '${settings['cameraControlsEnabled']}_'
                              '${settings['zoomEnabled']}',
                            ),
                            src: character.modelPath,
                            alt: l10n.translModelAlt,
                            ar: false,
                            autoRotate: false,
                            cameraControls:
                                settings['cameraControlsEnabled'] ?? true,
                            interactionPrompt: InteractionPrompt.none,
                            backgroundColor: Colors.transparent,
                            disableZoom: !(settings['zoomEnabled'] ?? true),
                            cameraOrbit: '0deg 75deg 2.5m',
                            cameraTarget: '0m 1.2m 0m',
                            fieldOfView: '30deg',
                            minCameraOrbit: 'auto 75deg auto',
                            maxCameraOrbit: 'auto 75deg auto',
                            relatedJs: _rigJs,
                            debugLogging: false,
                            javascriptChannels: {
                              JavascriptChannel(
                                'MooMooRigChannel',
                                onMessageReceived: _onReady,
                              ),
                            },
                            onWebViewCreated: (controller) {
                              _lastSentHash = null;
                              _controller = controller;
                              // Push even before "ready": JS queues the clip.
                              unawaited(() async {
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 400),
                                );
                                await _pushPayload(force: true);
                              }());
                            },
                          ),
                        ),
                        if (widget.note != null)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Text(
                              widget.note!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        if (_status.startsWith('error:') ||
                            _status.startsWith('waiting:bones'))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.m,
                              0,
                              AppSpacing.m,
                              AppSpacing.s,
                            ),
                            child: Text(
                              _status.startsWith('error:')
                                  ? 'Armature Mixamo introuvable sur ce modèle.'
                                  : 'Chargement de l’armature 3D…',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
          },
        );
  }
}
