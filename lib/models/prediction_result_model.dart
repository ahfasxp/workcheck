import 'package:equatable/equatable.dart';

class PredictionResultModel extends Equatable {
  final String id;
  final String description;
  final DateTime createdAt;

  const PredictionResultModel({
    required this.id,
    required this.description,
    required this.createdAt,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      id: json['id'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  @override
  List<Object?> get props => [id, description, createdAt];
}
