class BackendConfig {
  BackendConfig._();

  /// Set `--dart-define=USE_FIREBASE=true` to use Firebase instead of the local Dart backend.
  static const bool useFirebase =
      bool.fromEnvironment('USE_FIREBASE', defaultValue: false);
}
