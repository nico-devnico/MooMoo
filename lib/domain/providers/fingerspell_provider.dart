import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/api_client.dart';

class FingerspellModel {
  const FingerspellModel({
    required this.id,
    required this.name,
    required this.version,
    required this.active,
    this.accuracy,
    this.top3Accuracy,
    this.dataset,
    this.datasetDir,
    this.architecture,
    this.inputShape = const [],
    this.numClasses,
    this.epochsRan,
    this.maxPerClass,
    this.tfliteSizeKb,
    this.valAccuracy,
    this.testSamples,
    this.valSamples,
    this.runtime,
    this.hasTflite = false,
    this.metrics = const {},
  });

  final String id;
  final String name;
  final String version;
  final bool active;
  final double? accuracy;
  final double? top3Accuracy;
  final String? dataset;
  final String? datasetDir;
  final String? architecture;
  final List<int> inputShape;
  final int? numClasses;
  final int? epochsRan;
  final int? maxPerClass;
  final double? tfliteSizeKb;
  final double? valAccuracy;
  final int? testSamples;
  final int? valSamples;
  final String? runtime;
  final bool hasTflite;
  final Map<String, dynamic> metrics;

  factory FingerspellModel.fromJson(Map<String, dynamic> json) {
    final shape = json['input_shape'];
    return FingerspellModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['id'] as String? ?? '',
      version: json['version']?.toString() ?? '',
      active: json['active'] == true,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      top3Accuracy: (json['top3_accuracy'] as num?)?.toDouble(),
      dataset: json['dataset'] as String?,
      datasetDir: json['dataset_dir'] as String?,
      architecture: json['architecture'] as String?,
      inputShape: [
        for (final v in (shape is List ? shape : const []))
          if (v is num) v.toInt(),
      ],
      numClasses: (json['num_classes'] as num?)?.toInt(),
      epochsRan: (json['epochs_ran'] as num?)?.toInt(),
      maxPerClass: (json['max_per_class'] as num?)?.toInt(),
      tfliteSizeKb: (json['tflite_size_kb'] as num?)?.toDouble(),
      valAccuracy: (json['val_accuracy'] as num?)?.toDouble(),
      testSamples: (json['test_samples'] as num?)?.toInt(),
      valSamples: (json['val_samples'] as num?)?.toInt(),
      runtime: json['runtime'] as String?,
      hasTflite: json['has_tflite'] == true,
      metrics: json['metrics'] is Map
          ? Map<String, dynamic>.from(json['metrics'] as Map)
          : const {},
    );
  }

  List<({double epoch, double accuracy, double valAccuracy})> get history {
    final raw = metrics['history'];
    if (raw is! List) return const [];
    return [
      for (final row in raw)
        if (row is Map)
          (
            epoch: (row['epoch'] as num?)?.toDouble() ?? 0,
            accuracy: (row['accuracy'] as num?)?.toDouble() ?? 0,
            valAccuracy: (row['val_accuracy'] as num?)?.toDouble() ??
                (row['val_acc'] as num?)?.toDouble() ??
                0,
          ),
    ];
  }
}

class FingerspellTrainStatus {
  const FingerspellTrainStatus({
    required this.status,
    this.startedAt,
    this.finishedAt,
    this.message,
    this.versionId,
    this.error,
    this.logTail = const [],
  });

  final String status; // idle | running | succeeded | failed
  final String? startedAt;
  final String? finishedAt;
  final String? message;
  final String? versionId;
  final String? error;
  final List<String> logTail;

  bool get isRunning => status == 'running';

  factory FingerspellTrainStatus.fromJson(Map<String, dynamic> json) {
    final tail = json['log_tail'];
    return FingerspellTrainStatus(
      status: json['status'] as String? ?? 'idle',
      startedAt: json['started_at'] as String?,
      finishedAt: json['finished_at'] as String?,
      message: json['message'] as String?,
      versionId: json['version_id'] as String?,
      error: json['error'] as String?,
      logTail: [
        for (final line in (tail is List ? tail : const []))
          if (line != null) line.toString(),
      ],
    );
  }
}

final fingerspellModelsProvider =
    FutureProvider.autoDispose<List<FingerspellModel>>((ref) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final res = await ApiClient().get(
    '/api/fingerspell/models',
    accessToken: token,
    timeout: const Duration(seconds: 30),
  );
  final list = res['models'];
  if (list is! List) return const [];
  return [
    for (final item in list)
      if (item is Map) FingerspellModel.fromJson(Map<String, dynamic>.from(item)),
  ];
});

final fingerspellTrainStatusProvider =
    FutureProvider.autoDispose<FingerspellTrainStatus>((ref) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final res = await ApiClient().get(
    '/api/fingerspell/train/status',
    accessToken: token,
    timeout: const Duration(seconds: 15),
  );
  return FingerspellTrainStatus.fromJson(Map<String, dynamic>.from(res));
});

Future<void> activateFingerspellModel(WidgetRef ref, String id) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  await ApiClient().postJson(
    '/api/fingerspell/models/${Uri.encodeComponent(id)}/activate',
    accessToken: token,
    timeout: const Duration(seconds: 60),
  );
  ref.invalidate(fingerspellModelsProvider);
}

Future<FingerspellTrainStatus> startFingerspellTraining(
  WidgetRef ref, {
  int? maxPerClass,
  int? epochs,
}) async {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final body = <String, dynamic>{
    if (maxPerClass != null) 'max_per_class': maxPerClass,
    if (epochs != null) 'epochs': epochs,
  };
  final res = await ApiClient().postJson(
    '/api/fingerspell/train',
    body: body,
    accessToken: token,
    timeout: const Duration(seconds: 30),
  );
  ref.invalidate(fingerspellTrainStatusProvider);
  return FingerspellTrainStatus.fromJson(Map<String, dynamic>.from(res));
}
