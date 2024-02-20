enum PgTableType {
  predictionResults;

  String get name => toString();

  @override
  String toString() {
    switch (this) {
      case PgTableType.predictionResults:
        return 'prediction_results';
    }
  }
}
