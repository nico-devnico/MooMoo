import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ml_model.dart';
import '../services/api_client.dart';

abstract class MlModelRepository {
  Future<List<MlModel>> listModels();
  Future<MlModel?> getActiveModel();
  Future<ModelMetrics?> getLatestMetrics(String modelId);
  Future<Map<String, ModelMetrics?>> getLatestMetricsForModels(List<String> modelIds);
  Future<void> setActiveModel(String modelId);
  Future<TrainingJob> requestRetrain({
    required String dataset,
    String? baseModelId,
    required String requestedBy,
  });
  Future<List<TrainingJob>> listTrainingJobs({int limit = 30});
  Future<InferenceResult> infer({String? hint, List<int>? fileBytes, String? filename});

  /// Épellation ASL temps réel : une image → lettre + phrase (session).
  Future<InferenceResult> inferSpell({
    required List<int> fileBytes,
    String filename = 'frame.jpg',
    String? sessionId,
    bool reset = false,
    double threshold = 0.55,
    bool singleShot = false,
    bool? handDetected,
    bool live = false,
  });
}

class MlModelRepositoryImpl implements MlModelRepository {
  final SupabaseClient _supabase;
  final ApiClient _api;

  MlModelRepositoryImpl(this._supabase, {ApiClient? api})
      : _api = api ?? ApiClient();

  String? get _token => _supabase.auth.currentSession?.accessToken;

  @override
  Future<List<MlModel>> listModels() async {
    try {
      final res = await _api.get('/api/models', accessToken: _token);
      final list = res['models'];
      if (list is List) {
        return list
            .map((e) => MlModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // fall through
    }
    final response = await _supabase
        .from('ml_models')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => MlModel.fromJson(e)).toList();
  }

  @override
  Future<MlModel?> getActiveModel() async {
    try {
      final res = await _api.get('/api/models/active', accessToken: _token);
      final m = res['model'];
      if (m == null) return null;
      return MlModel.fromJson(Map<String, dynamic>.from(m as Map));
    } catch (_) {
      final response = await _supabase
          .from('ml_models')
          .select()
          .eq('is_active', true)
          .maybeSingle();
      if (response == null) return null;
      return MlModel.fromJson(response);
    }
  }

  @override
  Future<ModelMetrics?> getLatestMetrics(String modelId) async {
    try {
      final res = await _api.get(
        '/api/models/$modelId/metrics',
        accessToken: _token,
      );
      final m = res['metrics'];
      if (m == null) return null;
      return ModelMetrics.fromJson(Map<String, dynamic>.from(m as Map));
    } catch (_) {
      final response = await _supabase
          .from('model_metrics')
          .select()
          .eq('model_id', modelId)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return ModelMetrics.fromJson(response);
    }
  }

  @override
  Future<Map<String, ModelMetrics?>> getLatestMetricsForModels(
    List<String> modelIds,
  ) async {
    final result = <String, ModelMetrics?>{};
    for (final id in modelIds) {
      result[id] = await getLatestMetrics(id);
    }
    return result;
  }

  @override
  Future<void> setActiveModel(String modelId) async {
    final token = _token;
    if (token == null) throw Exception('Not authenticated');
    await _api.postJson(
      '/api/models/$modelId/activate',
      accessToken: token,
    );
  }

  @override
  Future<TrainingJob> requestRetrain({
    required String dataset,
    String? baseModelId,
    required String requestedBy,
  }) async {
    final token = _token;
    if (token == null) throw Exception('Not authenticated');
    final res = await _api.postJson(
      '/api/models/retrain',
      accessToken: token,
      body: {
        'dataset': dataset,
        'modelId': ?baseModelId,
      },
    );
    return TrainingJob.fromJson(Map<String, dynamic>.from(res['job'] as Map));
  }

  @override
  Future<List<TrainingJob>> listTrainingJobs({int limit = 30}) async {
    final token = _token;
    if (token == null) return [];
    try {
      final res = await _api.get('/api/models/jobs', accessToken: token);
      final list = res['jobs'];
      if (list is List) {
        return list
            .map((e) => TrainingJob.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    final response = await _supabase
        .from('training_jobs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((e) => TrainingJob.fromJson(e)).toList();
  }

  @override
  Future<InferenceResult> infer({
    String? hint,
    List<int>? fileBytes,
    String? filename,
  }) async {
    try {
      Map<String, dynamic> res;
      if (fileBytes != null) {
        res = await _api.postMultipart(
          '/api/infer',
          fileBytes: fileBytes,
          filename: filename ?? 'clip.mp4',
          fields: {
            if (hint != null && hint.isNotEmpty) 'hint': hint,
          },
          accessToken: _token,
          timeout: const Duration(seconds: 90),
          markUnreachableOnFailure: false,
        );
      } else {
        res = await _api.postJson(
          '/api/infer',
          accessToken: _token,
          body: {
            if (hint != null && hint.isNotEmpty) 'hint': hint,
          },
        );
      }
      return InferenceResult.fromJson(res);
    } on ApiException catch (e) {
      return InferenceResult.unavailable(e.message);
    } catch (e) {
      return InferenceResult.unavailable(e.toString());
    }
  }

  @override
  Future<InferenceResult> inferSpell({
    required List<int> fileBytes,
    String filename = 'frame.jpg',
    String? sessionId,
    bool reset = false,
    double threshold = 0.55,
    bool singleShot = false,
    bool? handDetected,
    bool live = false,
  }) async {
    try {
      ApiClient.resetAvailability();
      final res = await _api.postMultipart(
        '/api/infer/spell',
        fileBytes: fileBytes,
        filename: filename,
        fields: {
          if (sessionId != null && sessionId.isNotEmpty) 'session_id': sessionId,
          'threshold': threshold.toString(),
          if (reset) 'reset': 'true',
          if (singleShot) 'single_shot': 'true',
          if (handDetected != null) 'hand_detected': handDetected ? 'true' : 'false',
          if (live) 'live': 'true',
        },
        accessToken: _token,
        timeout: const Duration(seconds: 90),
        markUnreachableOnFailure: false,
      );
      return InferenceResult.fromJson(res);
    } on ApiException catch (e) {
      return InferenceResult.unavailable(e.message);
    } catch (e) {
      return InferenceResult.unavailable(e.toString());
    }
  }
}
