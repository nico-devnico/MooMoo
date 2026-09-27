import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moomoo/data/models/ml_model.dart';
import 'package:moomoo/data/repositories/ml_model_repository.dart';
import 'package:moomoo/domain/providers/auth_provider.dart';

final mlModelRepositoryProvider = Provider<MlModelRepository>((ref) {
  return MlModelRepositoryImpl(ref.watch(supabaseClientProvider));
});

final mlModelsProvider = FutureProvider.autoDispose<List<MlModel>>((ref) {
  return ref.watch(mlModelRepositoryProvider).listModels();
});

final activeMlModelProvider = FutureProvider.autoDispose<MlModel?>((ref) {
  return ref.watch(mlModelRepositoryProvider).getActiveModel();
});

final mlModelMetricsProvider =
    FutureProvider.autoDispose.family<ModelMetrics?, String>((ref, modelId) {
  return ref.watch(mlModelRepositoryProvider).getLatestMetrics(modelId);
});

final trainingJobsProvider =
    FutureProvider.autoDispose<List<TrainingJob>>((ref) {
  return ref.watch(mlModelRepositoryProvider).listTrainingJobs();
});
