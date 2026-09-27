/// Training platform data, as written by the ML worker in Supabase.
library;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
double? _num(Object? v) => (v as num?)?.toDouble();
int? _int(Object? v) => (v as num?)?.toInt();
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};
List<String> _strings(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

enum DatasetStatus { registered, analyzing, analyzed, preprocessing, ready, failed }

class MlDataset {
  final String id;
  final String name;
  final String languageCode;
  final String sourceType;
  final String uri;
  final String mediaFormat;
  final bool isStructured;
  final bool isLabeled;
  final Map<String, String> labelMapping;
  final DatasetStatus status;
  final Map<String, dynamic> analysis;
  final Map<String, dynamic> preprocessing;
  final String? errorMessage;
  final DateTime? createdAt;

  const MlDataset({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.sourceType,
    required this.uri,
    required this.mediaFormat,
    required this.isStructured,
    required this.isLabeled,
    required this.labelMapping,
    required this.status,
    required this.analysis,
    required this.preprocessing,
    this.errorMessage,
    this.createdAt,
  });

  factory MlDataset.fromJson(Map<String, dynamic> json) => MlDataset(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        languageCode: json['language_code'] as String? ?? '',
        sourceType: json['source_type'] as String? ?? 'local',
        uri: json['uri'] as String? ?? '',
        mediaFormat: json['media_format'] as String? ?? 'auto',
        isStructured: json['is_structured'] as bool? ?? true,
        isLabeled: json['is_labeled'] as bool? ?? true,
        labelMapping: _map(json['label_mapping'])
            .map((k, v) => MapEntry(k, v.toString())),
        status: DatasetStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DatasetStatus.registered,
        ),
        analysis: _map(json['analysis']),
        preprocessing: _map(json['preprocessing']),
        errorMessage: json['error_message'] as String?,
        createdAt: _date(json['created_at']),
      );

  bool get isBusy =>
      status == DatasetStatus.analyzing || status == DatasetStatus.preprocessing;
  bool get isTrainable => analysis['trainable'] == true;
  int get classesCount => _int(analysis['classes_count']) ?? 0;
  int get labeledSamples => _int(analysis['samples_labeled']) ?? 0;
  int get filesTotal => _int(analysis['files_total']) ?? 0;
  int get signersCount => _int(analysis['signers_count']) ?? 0;
  int get invalidCount => _int(analysis['invalid_count']) ?? 0;
  int get duplicateGroups => _int(analysis['duplicate_groups']) ?? 0;
  int get unlabeledSamples => _int(analysis['samples_unlabeled']) ?? 0;
  double? get imbalanceRatio =>
      _num(_map(analysis['class_balance'])['imbalance_ratio']);
  List<String> get warnings => _strings(analysis['warnings']);
  List<String> get recommendations => _strings(analysis['recommendations']);
  Map<String, int> get classCounts => _map(analysis['classes'])
      .map((k, v) => MapEntry(k, (v as num).toInt()));
  Map<String, dynamic> get media => _map(analysis['media']);
  int get preparedSamples => _int(preprocessing['samples']) ?? 0;
  int get rejectedSamples => _int(preprocessing['rejected']) ?? 0;
}

class TrainingJobDetail {
  final String id;
  final String kind;
  final String status;
  final double progress;
  final String dataset;
  final String? datasetId;
  final String? languageCode;
  final Map<String, dynamic> config;
  final int? currentEpoch;
  final int? totalEpochs;
  final String? message;
  final String? errorMessage;
  final Map<String, dynamic> result;
  final String? resultModelId;
  final int attempts;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? heartbeatAt;

  const TrainingJobDetail({
    required this.id,
    required this.kind,
    required this.status,
    required this.progress,
    required this.dataset,
    this.datasetId,
    this.languageCode,
    this.config = const {},
    this.currentEpoch,
    this.totalEpochs,
    this.message,
    this.errorMessage,
    this.result = const {},
    this.resultModelId,
    this.attempts = 0,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
    this.heartbeatAt,
  });

  factory TrainingJobDetail.fromJson(Map<String, dynamic> json) =>
      TrainingJobDetail(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'train',
        status: json['status'] as String? ?? 'queued',
        progress: _num(json['progress']) ?? 0,
        dataset: json['dataset'] as String? ?? '',
        datasetId: json['dataset_id'] as String?,
        languageCode: json['language_code'] as String?,
        config: _map(json['config']),
        currentEpoch: _int(json['current_epoch']),
        totalEpochs: _int(json['total_epochs']),
        message: json['message'] as String?,
        errorMessage: json['error_message'] as String?,
        result: _map(json['result']),
        resultModelId: json['result_model_id'] as String?,
        attempts: _int(json['attempts']) ?? 0,
        createdAt: _date(json['created_at']),
        startedAt: _date(json['started_at']),
        finishedAt: _date(json['finished_at']),
        heartbeatAt: _date(json['heartbeat_at']),
      );

  bool get isActive =>
      status == 'queued' || status == 'running' || status == 'cancelling';
  bool get isCancellable => status == 'queued' || status == 'running';

  Duration? get elapsed {
    final start = startedAt;
    if (start == null) return null;
    return (finishedAt ?? DateTime.now()).difference(start);
  }
}

class MlExperiment {
  final String id;
  final String code;
  final String? jobId;
  final String? datasetId;
  final String languageCode;
  final Map<String, dynamic> config;
  final String status;
  final int? budgetEpochs;
  final int? rung;
  final int currentEpoch;
  final int? totalEpochs;
  final double? bestValAccuracy;
  final double? bestValLoss;
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> perClass;
  final List<List<int>> confusionMatrix;
  final List<String> labels;
  final int? paramsCount;
  final int? modelSizeBytes;
  final double? durationS;
  final Map<String, dynamic> artifacts;
  final String? modelId;
  final String? errorMessage;
  final DateTime? createdAt;

  const MlExperiment({
    required this.id,
    required this.code,
    this.jobId,
    this.datasetId,
    required this.languageCode,
    required this.config,
    required this.status,
    this.budgetEpochs,
    this.rung,
    this.currentEpoch = 0,
    this.totalEpochs,
    this.bestValAccuracy,
    this.bestValLoss,
    this.metrics = const {},
    this.perClass = const [],
    this.confusionMatrix = const [],
    this.labels = const [],
    this.paramsCount,
    this.modelSizeBytes,
    this.durationS,
    this.artifacts = const {},
    this.modelId,
    this.errorMessage,
    this.createdAt,
  });

  factory MlExperiment.fromJson(Map<String, dynamic> json) => MlExperiment(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        jobId: json['job_id'] as String?,
        datasetId: json['dataset_id'] as String?,
        languageCode: json['language_code'] as String? ?? '',
        config: _map(json['config']),
        status: json['status'] as String? ?? 'queued',
        budgetEpochs: _int(json['budget_epochs']),
        rung: _int(json['rung']),
        currentEpoch: _int(json['current_epoch']) ?? 0,
        totalEpochs: _int(json['total_epochs']),
        bestValAccuracy: _num(json['best_val_accuracy']),
        bestValLoss: _num(json['best_val_loss']),
        metrics: _map(json['metrics']),
        perClass: (json['per_class'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        confusionMatrix: (json['confusion_matrix'] as List? ?? const [])
            .map((row) => (row as List).map((v) => (v as num).toInt()).toList())
            .toList(),
        labels: _strings(json['labels']),
        paramsCount: _int(json['params_count']),
        modelSizeBytes: _int(json['model_size_bytes']),
        durationS: _num(json['duration_s']),
        artifacts: _map(json['artifacts']),
        modelId: json['model_id'] as String?,
        errorMessage: json['error_message'] as String?,
        createdAt: _date(json['created_at']),
      );

  Map<String, dynamic> get modelConfig => _map(config['model']);

  /// Test metrics when a test split exists, validation otherwise.
  Map<String, dynamic> get evaluation {
    final test = _map(metrics['test']);
    return test.isNotEmpty ? test : _map(metrics['validation']);
  }

  String? get evaluatedOn => metrics['evaluated_on'] as String?;
  double? get accuracy => _num(evaluation['accuracy']);
  double? get macroF1 => _num(evaluation['macro_f1']);
  double? get precision => _num(evaluation['precision']);
  double? get recall => _num(evaluation['recall']);
  double? get f1 => _num(evaluation['f1']);
  List<String> get dataWarnings =>
      _strings(_map(metrics['data'])['warnings']);

  Map<String, int> get artifactFiles => _map(artifacts['files']).map(
        (k, v) => MapEntry(k, _int(_map(v)['size_bytes']) ?? 0),
      );

  String get architectureText {
    final units = (modelConfig['lstm_units'] as List? ?? const []).join('-');
    final dense = (modelConfig['dense_units'] as List? ?? const []);
    return 'LSTM $units${dense.isEmpty ? '' : ' · Dense ${dense.join('-')}'}';
  }
}

class EpochMetric {
  final int epoch;
  final double? loss;
  final double? accuracy;
  final double? valLoss;
  final double? valAccuracy;
  final double? learningRate;
  final double? durationS;

  const EpochMetric({
    required this.epoch,
    this.loss,
    this.accuracy,
    this.valLoss,
    this.valAccuracy,
    this.learningRate,
    this.durationS,
  });

  factory EpochMetric.fromJson(Map<String, dynamic> json) => EpochMetric(
        epoch: _int(json['epoch']) ?? 0,
        loss: _num(json['loss']),
        accuracy: _num(json['accuracy']),
        valLoss: _num(json['val_loss']),
        valAccuracy: _num(json['val_accuracy']),
        learningRate: _num(json['learning_rate']),
        durationS: _num(json['duration_s']),
      );
}

class TrainingLogLine {
  final int id;
  final String level;
  final String message;
  final DateTime? createdAt;

  const TrainingLogLine({
    required this.id,
    required this.level,
    required this.message,
    this.createdAt,
  });

  factory TrainingLogLine.fromJson(Map<String, dynamic> json) => TrainingLogLine(
        id: _int(json['id']) ?? 0,
        level: json['level'] as String? ?? 'info',
        message: json['message'] as String? ?? '',
        createdAt: _date(json['created_at']),
      );
}

/// Registry stages, in promotion order.
const kModelStages = [
  'training',
  'trained',
  'evaluated',
  'validated',
  'staging',
  'production',
  'archived',
];

class RegistryModel {
  final String id;
  final String name;
  final String version;
  final String dataset;
  final String? languageCode;
  final String stage;
  final String? description;
  final String? experimentId;
  final List<String> classes;
  final Map<String, dynamic> architecture;
  final List<int> inputShape;
  final Map<String, dynamic> hyperparameters;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> tfliteMetrics;
  final double? trainingDurationS;
  final int? sizeBytes;
  final int? tfliteSizeBytes;
  final DateTime? createdAt;
  final DateTime? promotedAt;

  const RegistryModel({
    required this.id,
    required this.name,
    required this.version,
    required this.dataset,
    this.languageCode,
    required this.stage,
    this.description,
    this.experimentId,
    this.classes = const [],
    this.architecture = const {},
    this.inputShape = const [],
    this.hyperparameters = const {},
    this.metrics = const {},
    this.tfliteMetrics = const {},
    this.trainingDurationS,
    this.sizeBytes,
    this.tfliteSizeBytes,
    this.createdAt,
    this.promotedAt,
  });

  factory RegistryModel.fromJson(Map<String, dynamic> json) => RegistryModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        version: json['version'] as String? ?? '',
        dataset: json['dataset'] as String? ?? '',
        languageCode: json['language_code'] as String?,
        stage: json['stage'] as String? ?? 'trained',
        description: json['description'] as String?,
        experimentId: json['experiment_id'] as String?,
        classes: _strings(json['classes']),
        architecture: _map(json['architecture']),
        inputShape: (json['input_shape'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        hyperparameters: _map(json['hyperparameters']),
        metrics: _map(json['metrics']),
        tfliteMetrics: _map(json['tflite_metrics']),
        trainingDurationS: _num(json['training_duration_s']),
        sizeBytes: _int(json['size_bytes']),
        tfliteSizeBytes: _int(json['tflite_size_bytes']),
        createdAt: _date(json['created_at']),
        promotedAt: _date(json['promoted_at']),
      );

  Map<String, dynamic> get evaluation {
    final test = _map(metrics['test']);
    return test.isNotEmpty ? test : _map(metrics['validation']);
  }

  double? get accuracy => _num(evaluation['accuracy']);
  double? get macroF1 => _num(evaluation['macro_f1']);
  Map<String, dynamic> get tfliteBenchmark => _map(tfliteMetrics['benchmark']);
  bool? get mobileCompatible => tfliteMetrics['mobile_compatible'] as bool?;
  String get architectureText => architecture['text'] as String? ?? '';
  String get language => languageCode ?? dataset;

  /// Next stages an admin may move this model to (see promote_ml_model).
  List<String> get allowedTransitions => switch (stage) {
        'evaluated' => ['validated', 'archived'],
        'validated' => ['staging', 'archived'],
        'staging' => ['production', 'archived'],
        'production' => ['archived'],
        'archived' => ['staging'],
        'trained' => ['archived'],
        _ => const [],
      };
}
