import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/ml_training.dart';
import '../../../domain/providers/ml_training_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'admin_shell.dart';
import 'ml/ml_common.dart';
import 'ml/ml_datasets_tab.dart';
import 'ml/ml_experiments_tab.dart';
import 'ml/ml_jobs_tab.dart';
import 'ml/ml_registry_tab.dart';

/// Refresh cadence while a job is queued or running.
const _pollInterval = Duration(seconds: 3);

/// ML training platform: datasets, jobs, experiments and model registry.
///
/// The app only writes datasets and job requests; the Python worker does the
/// work and writes progress back, so this screen polls while jobs are active.
class AdminModelsScreen extends ConsumerStatefulWidget {
  const AdminModelsScreen({super.key});

  @override
  ConsumerState<AdminModelsScreen> createState() => _AdminModelsScreenState();
}

class _AdminModelsScreenState extends ConsumerState<AdminModelsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  void _syncPolling(List<TrainingJobDetail>? jobs) {
    final active = jobs?.any((j) => j.isActive) ?? false;
    if (active && _poll == null) {
      _poll = Timer.periodic(_pollInterval, (_) {
        if (mounted) refreshMlTraining(ref);
      });
    } else if (!active && _poll != null) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _goToJobs() => _tabs.animateTo(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<AsyncValue<List<TrainingJobDetail>>>(
      mlJobsProvider,
      (_, next) {
        if (next.hasValue) _syncPolling(next.value);
      },
    );
    final isMobile = context.isMobile;

    return AdminShell(
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              0,
            ),
            child: MlConstrained(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(l10n.adminModels, style: AppTextStyles.h2),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          l10n.mlScreenSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  MlIconButton(
                    icon: AppIcons.refresh,
                    tooltip: l10n.admxRefresh,
                    onPressed: () => refreshMlTraining(ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: MlConstrained(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border(context)),
                  ),
                ),
                child: TabBar(
                  controller: _tabs,
                  isScrollable: isMobile,
                  tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: AppTextStyles.bodyMedium,
                  tabs: [
                    Tab(
                      icon: const Icon(AppIcons.database, size: 20),
                      text: l10n.mlTabDatasets,
                    ),
                    Tab(
                      icon: const Icon(PhosphorIconsRegular.brain, size: 20),
                      text: l10n.mlTabJobs,
                    ),
                    Tab(
                      icon: const Icon(PhosphorIconsRegular.flask, size: 20),
                      text: l10n.mlTabExperiments,
                    ),
                    Tab(
                      icon: const Icon(PhosphorIconsRegular.package, size: 20),
                      text: l10n.mlTabRegistry,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                MlDatasetsTab(onJobQueued: _goToJobs),
                MlJobsTab(onJobQueued: _goToJobs),
                const MlExperimentsTab(),
                MlRegistryTab(onJobQueued: _goToJobs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
