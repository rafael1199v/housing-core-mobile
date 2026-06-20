class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:5065',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const String mapsWebApiKey = String.fromEnvironment(
    'MAPS_WEB_API_KEY',
  );

  static const String mapsCloudMapId = String.fromEnvironment(
    'MAPS_CLOUD_MAP_ID',
  );

  static String? get googleWebClientIdOrNull =>
      googleWebClientId.isEmpty ? null : googleWebClientId;

  static String? get googleServerClientIdOrNull =>
      googleServerClientId.isEmpty ? null : googleServerClientId;

  static String? get mapsWebApiKeyOrNull =>
      mapsWebApiKey.isEmpty ? null : mapsWebApiKey;

  static String? get mapsCloudMapIdOrNull =>
    mapsCloudMapId.isEmpty ? null : mapsCloudMapId;
}
