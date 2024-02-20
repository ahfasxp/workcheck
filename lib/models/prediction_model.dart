import 'package:equatable/equatable.dart';
import 'package:workcheck/enums/prediction_status.dart';

class PredictionModel extends Equatable {
  final String id;
  final String version;
  final PredictionUrls urls;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final PredictionStatus status;
  final Map<String, dynamic> input;
  final dynamic output;
  final String? error;
  final String logs;

  const PredictionModel({
    required this.id,
    required this.version,
    required this.urls,
    required this.createdAt,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    required this.input,
    required this.output,
    required this.error,
    required this.logs,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'],
      version: json['version'],
      urls: PredictionUrls.fromJson(json['urls']),
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      status: PredictionStatus.fromString(json['status']),
      input: json['input'],
      output: json['output'],
      error: json['error'],
      logs: json['logs'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        version,
        urls,
        createdAt,
        startedAt,
        completedAt,
        status,
        input,
        output,
        error,
        logs,
      ];
}

class PredictionUrls {
  final String get;
  final String cancel;
  final String? stream;

  PredictionUrls({
    required this.get,
    required this.cancel,
    this.stream,
  });

  factory PredictionUrls.fromJson(Map<String, dynamic> json) {
    return PredictionUrls(
      get: json['get'],
      cancel: json['cancel'],
      stream: json['stream'],
    );
  }
}
