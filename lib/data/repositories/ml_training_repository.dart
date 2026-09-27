import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ml_training.dart';

/// Admin side of the training platform.
///
/// Everything goes straight to Supabase under the admin's RLS: the app only
/// writes datasets and job requests; the ML worker consumes the queue and
/// writes experiments, epochs, logs and registry entries back. Closing the app
/// therefore never interrupts a job.
class MlTrainingRepository {
  final SupabaseClient _db;

  MlTrainingRepository(this._db);

  String? get _userId => _db.auth.currentUser?.id;

  // ---------------------------------------------------------------- datasets
  Future<List<MlDataset>> listDatasets() async {
    final rows = await _db
        .from('ml_datasets')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => MlDataset.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Registers the dataset and queues its analysis in one go.
  Future<MlDataset> createDataset({
    required String name,
    required String languageCode,
    required String sourceType,
    required String uri,
    required String mediaFormat,
    required bool isStructured,
    required bool isLabeled,
    Map<String, String> labelMapping = const {},
  }) async {
    final row = await _db
        .from('ml_datasets')
        .insert({
          'name': name.trim(),
          'language_code': languageCode.trim().toUpperCase(),
          'source_type': sourceType,
          'uri': uri.trim(),
          'media_format': mediaFormat,
          'is_structured': isStructured,
          'is_labeled': isLabeled,
          'label_mapping': labelMapping,
          'created_by': _userId,
        })
        .select()
        .single();
    final dataset = MlDataset.fromJson(row);
    await enqueue(kind: 'analyze', dataset: dataset);
    return dataset;
  }

  Future<void> updateLabelMapping(String datasetId, Map<String, String> mapping) {
    return _db
        .from('ml_datasets')
        .update({'label_mapping': mapping, 'status': 'registered'})
        .eq('id', datasetId);
  }

  Future<void> deleteDataset(String id) =>
      _db.from('ml_datasets').delete().eq('id', id);

  // -------------------------------------------------------------------- jobs
  Future<TrainingJobDetail> enqueue({
    required String kind,
    MlDataset? dataset,
    String? languageCode,
    Map<String, dynamic> config = const {},
    String? modelId,
  }) async {
    final row = await _db
        .from('training_jobs')
        .insert({
          'kind': kind,
          'dataset': dataset?.name ?? kind,
          'dataset_id': dataset?.id,
          'language_code': languageCode ?? dataset?.languageCode,
          'config': config,
          'model_id': modelId,
          'requested_by': _userId,
          'status': 'queued',
          'progress': 0,
        })
        .select()
        .single();
    return TrainingJobDetail.fromJson(row);
  }

  Future<List<TrainingJobDetail>> listJobs({int limit = 40}) async {
    final rows = await _db
        .from('training_jobs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => TrainingJobDetail.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// A queued job is cancelled at once; a running one is asked to stop and
  /// the worker confirms after the current epoch.
  Future<void> cancelJob(TrainingJobDetail job) async {
    if (job.status == 'queued') {
      await _db
          .from('training_jobs')
          .update({
            'status': 'cancelled',
            'finished_at': DateTime.now().toUtc().toIso8601String(),
            'message': 'Annulé avant démarrage',
          })
          .eq('id', job.id)
          .eq('status', 'queued');
    } else if (job.status == 'running') {
      await _db
          .from('training_jobs')
          .update({'status': 'cancelling'})
          .eq('id', job.id)
          .eq('status', 'running');
    }
  }

  Future<List<TrainingLogLine>> jobLogs(String jobId, {int limit = 200}) async {
    final rows = await _db
        .from('training_logs')
        .select('id, level, message, created_at')
        .eq('job_id', jobId)
        .neq('level', 'debug')
        .order('id', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((e) => TrainingLogLine.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
        .reversed
        .toList();
  }

  // ------------------------------------------------------------- experiments
  Future<List<MlExperiment>> listExperiments({String? jobId, String? language}) async {
    var query = _db.from('ml_experiments').select();
    if (jobId != null) query = query.eq('job_id', jobId);
    if (language != null) query = query.eq('language_code', language);
    final rows = await query.order('created_at', ascending: false).limit(200);
    return (rows as List)
        .map((e) => MlExperiment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<EpochMetric>> epochs(String experimentId) async {
    final rows = await _db
        .from('ml_epoch_metrics')
        .select()
        .eq('experiment_id', experimentId)
        .order('epoch');
    return (rows as List)
        .map((e) => EpochMetric.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<TrainingJobDetail> registerExperiment(MlExperiment exp, {String quantization = 'dynamic'}) {
    return enqueue(
      kind: 'evaluate',
      languageCode: exp.languageCode,
      config: {'experiment_id': exp.id, 'quantization': quantization},
    );
  }

  // ---------------------------------------------------------------- registry
  Future<List<RegistryModel>> listRegistry() async {
    final rows = await _db
        .from('ml_models')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => RegistryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> setStage(String modelId, String stage) async {
    await _db.rpc('promote_ml_model', params: {
      'p_model_id': modelId,
      'p_stage': stage,
    });
  }

  Future<TrainingJobDetail> convertModel(RegistryModel model, {String quantization = 'dynamic'}) {
    return enqueue(
      kind: 'convert',
      languageCode: model.languageCode,
      modelId: model.id,
      config: {'model_id': model.id, 'quantization': quantization},
    );
  }

  /// Most recent worker heartbeat, to tell the admin whether jobs will run.
  Future<DateTime?> lastWorkerHeartbeat() async {
    final row = await _db
        .from('training_jobs')
        .select('heartbeat_at')
        .not('heartbeat_at', 'is', null)
        .order('heartbeat_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final v = row?['heartbeat_at'];
    return v is String ? DateTime.tryParse(v) : null;
  }
}
