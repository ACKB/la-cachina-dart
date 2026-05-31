/// Parámetros de conexión a SQL Server local
///
/// Configura mediante --dart-define al compilar:
///   flutter run \
///     --dart-define=DB_HOST=localhost \
///     --dart-define=DB_PORT=1433 \
///     --dart-define=DB_NAME=KChinaFIEI \
///     --dart-define=DB_USER=sa \
///     --dart-define=DB_PASSWORD=TuContraseña
class DatabaseConfig {
  DatabaseConfig._();

  static const String host =
      String.fromEnvironment('DB_HOST', defaultValue: 'localhost');
  static const int port =
      int.fromEnvironment('DB_PORT', defaultValue: 1433);
  static const String database =
      String.fromEnvironment('DB_NAME', defaultValue: 'KChinaFIEI');
  static const String username =
      String.fromEnvironment('DB_USER', defaultValue: 'sa');
  static const String password =
      String.fromEnvironment('DB_PASSWORD', defaultValue: '');
  static const bool useWindowsAuth =
      bool.fromEnvironment('DB_WINDOWS_AUTH', defaultValue: false);

  static const int connectionTimeoutSeconds = 30;
  static const int commandTimeoutSeconds    = 60;

  static String get connectionString {
    if (useWindowsAuth) {
      return 'Server=$host,$port;Database=$database;'
          'Trusted_Connection=True;TrustServerCertificate=True;'
          'Connection Timeout=$connectionTimeoutSeconds;';
    }
    return 'Server=$host,$port;Database=$database;'
        'User Id=$username;Password=$password;'
        'TrustServerCertificate=True;'
        'Connection Timeout=$connectionTimeoutSeconds;';
  }
}
