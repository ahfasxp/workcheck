import 'package:equatable/equatable.dart';

class PredictionResultModel extends Equatable {
  final String id;
  final String message;
  final DateTime createdAt;

  const PredictionResultModel({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      id: json['id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, message, createdAt];
}
