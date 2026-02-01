class CompositeSocketHealth {
  CompositeSocketHealth._();

  static final CompositeSocketHealth instance = CompositeSocketHealth._();

  bool secondaryAvailable = true;
  DateTime lastUpdated = DateTime.fromMillisecondsSinceEpoch(0);

  void setSecondaryAvailable(bool value) {
    secondaryAvailable = value;
    lastUpdated = DateTime.now();
  }
}
