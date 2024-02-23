enum PgTableType {
  predictionResults,
  devices;

  String get name => toString();

  @override
  String toString() {
    switch (this) {
      case PgTableType.predictionResults:
        return 'prediction_results';
      case PgTableType.devices:
        return 'devices';
    }
  }
}
