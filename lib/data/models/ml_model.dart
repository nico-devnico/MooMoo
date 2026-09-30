class MlModel {
  final String id;
  final String name;
  final String version;
  final String dataset;
  final String? description;
  final String? artifactUrl;
  final bool isActive;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MlModel({
    required this.id,
    required this.name,
    required this.version,
    required this.dataset,
    this.description,
    this.artifactUrl,
    this.isActive = false,
    this.status = 'ready',
    this.createdAt,
    this.updatedAt,
  });

  factory MlModel.fromJson(Map<String, dynamic> json) {
    return MlModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      dataset: json['dataset'] as String? ?? 'other',
      description: json['description'] as String?,
      artifactUrl: json['artifact_url'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      status: json['status'] as String? ?? 'ready',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  String get displayLabel => '$name · $version ($dataset)';
}

class ModelMetrics {
  final String id;
  final String modelId;
  final double? accuracy;
  final double? latencyMs;
  final int inferenceCount;
  final String? dataset;
  final DateTime? recordedAt;
  final String? notes;

  const ModelMetrics({
    required this.id,
    required this.modelId,
    this.accuracy,
    this.latencyMs,
    this.inferenceCount = 0,
    this.dataset,
    this.recordedAt,
    this.notes,
  });

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      id: json['id'] as String,
      modelId: json['model_id'] as String,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      latencyMs: (json['latency_ms'] as num?)?.toDouble(),
      inferenceCount: (json['inference_count'] as num?)?.toInt() ?? 0,
      dataset: json['dataset'] as String?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}

class TrainingJob {
  final String id;
  final String? modelId;
  final String? requestedBy;
  final String dataset;
  final String status;
  final double progress;
  final String? errorMessage;
  final String? resultModelId;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const TrainingJob({
    required this.id,
    this.modelId,
    this.requestedBy,
    required this.dataset,
    required this.status,
    this.progress = 0,
    this.errorMessage,
    this.resultModelId,
    this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  factory TrainingJob.fromJson(Map<String, dynamic> json) {
    return TrainingJob(
      id: json['id'] as String,
      modelId: json['model_id'] as String?,
      requestedBy: json['requested_by'] as String?,
      dataset: json['dataset'] as String? ?? 'WASL+LSFB',
      status: json['status'] as String? ?? 'queued',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      errorMessage: json['error_message'] as String?,
      resultModelId: json['result_model_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
    );
  }
}

class InferenceResult {
  final bool ok;
  final String? label;
  final double? confidence;
  final double? latencyMs;
  final MlModel? model;
  final String? errorCode;
  final String? errorMessage;

  /// Best candidates, most likely first (the label is the first one).
  final List<String> topLabels;

  /// Phrase assemblée par épellation (lettres + espaces), si fournie.
  final String? text;

  /// Lettre / commande réellement ajoutée à la phrase (après stabilité).
  final String? committed;

  /// Mode d'inférence : `fingerspell` ou null (signe en mouvement).
  final String? mode;

  /// Identifiant de session d'épellation à renvoyer aux frames suivantes.
  final String? sessionId;

  /// True si une main a été détectée dans la frame (prétraitement ML).
  final bool handDetected;

  const InferenceResult({
    required this.ok,
    this.label,
    this.confidence,
    this.latencyMs,
    this.model,
    this.errorCode,
    this.errorMessage,
    this.topLabels = const [],
    this.text,
    this.committed,
    this.mode,
    this.sessionId,
    this.handDetected = true,
  });

  factory InferenceResult.fromJson(Map<String, dynamic> json) {
    final prediction = json['prediction'] as Map<String, dynamic>?;
    final modelJson = json['model'] as Map<String, dynamic>?;
    return InferenceResult(
      ok: json['ok'] == true,
      label: prediction?['label'] as String?,
      confidence: (prediction?['confidence'] as num?)?.toDouble(),
      latencyMs: (prediction?['latency_ms'] as num?)?.toDouble(),
      model: modelJson != null
          ? MlModel(
              id: modelJson['id'] as String? ?? '',
              name: modelJson['name'] as String? ?? '',
              version: modelJson['version'] as String? ?? '',
              dataset: modelJson['dataset'] as String? ?? '',
              isActive: true,
            )
          : null,
      errorCode: json['error'] as String?,
      errorMessage: json['message'] as String? ?? json['detail'] as String?,
      topLabels: [
        for (final item in (prediction?['top'] as List? ?? const []))
          if (item is Map && item['label'] is String) item['label'] as String,
      ],
      text: prediction?['text'] as String? ?? json['text'] as String?,
      committed: prediction?['committed'] as String?,
      mode: prediction?['mode'] as String? ?? json['mode'] as String?,
      sessionId: json['session_id'] as String?,
      handDetected: prediction?['hand_detected'] != false &&
          json['hand_detected'] != false,
    );
  }

  factory InferenceResult.unavailable(String message) {
    return InferenceResult(
      ok: false,
      errorCode: 'backend_unavailable',
      errorMessage: message,
    );
  }
}
