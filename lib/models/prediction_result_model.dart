import 'package:equatable/equatable.dart';

class PredictionResultModel extends Equatable {
  final String id;
  final String output;
  final DateTime createdAt;

  const PredictionResultModel({
    required this.id,
    required this.output,
    required this.createdAt,
  });

  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      id: json['id'] as String,
      output: json['output'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, output, createdAt];
}
