import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ml_training.dart';
import '../../data/repositories/ml_training_repository.dart';
import 'auth_provider.dart';

final mlTrainingRepositoryProvider = Provider<MlTrainingRepository>((ref) {
  return MlTrainingRepository(ref.watch(supabaseClientProvider));
});

final mlDatasetsProvider = FutureProvider.autoDispose<List<MlDataset>>((ref) {
  return ref.watch(mlTrainingRepositoryProvider).listDatasets();
});

final mlJobsProvider = FutureProvider.autoDispose<List<TrainingJobDetail>>((ref) {
  return ref.watch(mlTrainingRepositoryProvider).listJobs();
});

/// Experiments, optionally restricted to one language (null = all).
final mlExperimentsProvider =
    FutureProvider.autoDispose.family<List<MlExperiment>, String?>((ref, language) {
  return ref.watch(mlTrainingRepositoryProvider).listExperiments(language: language);
});

final mlJobExperimentsProvider =
    FutureProvider.autoDispose.family<List<MlExperiment>, String>((ref, jobId) {
  return ref.watch(mlTrainingRepositoryProvider).listExperiments(jobId: jobId);
});

final mlEpochsProvider =
    FutureProvider.autoDispose.family<List<EpochMetric>, String>((ref, experimentId) {
  return ref.watch(mlTrainingRepositoryProvider).epochs(experimentId);
});

final mlJobLogsProvider =
    FutureProvider.autoDispose.family<List<TrainingLogLine>, String>((ref, jobId) {
  return ref.watch(mlTrainingRepositoryProvider).jobLogs(jobId);
});

final mlRegistryProvider = FutureProvider.autoDispose<List<RegistryModel>>((ref) {
  return ref.watch(mlTrainingRepositoryProvider).listRegistry();
});

final mlWorkerHeartbeatProvider = FutureProvider.autoDispose<DateTime?>((ref) {
  return ref.watch(mlTrainingRepositoryProvider).lastWorkerHeartbeat();
});

/// Refreshes everything that a running job changes.
void refreshMlTraining(WidgetRef ref) {
  ref
    ..invalidate(mlDatasetsProvider)
    ..invalidate(mlJobsProvider)
    ..invalidate(mlExperimentsProvider)
    ..invalidate(mlJobExperimentsProvider)
    ..invalidate(mlEpochsProvider)
    ..invalidate(mlJobLogsProvider)
    ..invalidate(mlRegistryProvider)
    ..invalidate(mlWorkerHeartbeatProvider);
}
