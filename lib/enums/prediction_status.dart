enum PredictionStatus {
  starting,
  processing,
  succeeded,
  failed,
  canceled;

  static PredictionStatus fromString(String status) {
    return PredictionStatus.values.firstWhere(
      (statusEnum) => statusEnum.name.toLowerCase() == status.toLowerCase(),
    );
  }
}
