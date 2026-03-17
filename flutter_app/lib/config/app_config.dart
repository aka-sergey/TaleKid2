class AppConfig {
  static const String appName = 'TaleKID';
  static const String appVersion = '1.0.0';

  // API Configuration
  // In production, this will be the Railway URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // Timeouts (generous for Railway cold-start latency)
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Generation polling interval
  static const Duration pollingInterval = Duration(seconds: 3);

  // Max photos per character
  static const int maxPhotosPerCharacter = 3;

  // Legal URLs
  static const String termsUrl = 'https://www.talekid.ai/terms';
  static const String privacyUrl = 'https://www.talekid.ai/privacy';
  static const String consentUrl = 'https://www.talekid.ai/consent';
}
