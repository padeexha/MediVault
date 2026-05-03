class Constants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://medi-vault-backend-28w8.onrender.com/api',
  );

  // Auth endpoints
  static const String registerPatient = '$baseUrl/auth/register/patient';
  static const String registerDoctor = '$baseUrl/auth/register/doctor';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String updateProfile = '$baseUrl/auth/profile';

  // Record endpoints
  static const String records = '$baseUrl/records';
  static const String uploadRecord = '$baseUrl/records/upload';
  static const String search = '$baseUrl/search';
  static const String searchDoctor = '$baseUrl/auth/search-doctor';
  static const String doctors = '$baseUrl/auth/doctors';

  // Permission endpoints
  static const String permissions = '$baseUrl/permissions';
  static const String grantPermission = '$baseUrl/permissions/grant';
  static const String myDoctors = '$baseUrl/permissions/my-doctors';
  static const String sharedWithMe = '$baseUrl/permissions/shared-with-me';

  // Audit endpoints
  static const String auditLogs = '$baseUrl/audit/my-logs';

  // App colors
  static const int primaryColor = 0xFF0F6E56;
  static const int secondaryColor = 0xFF1D9E75;
  static const int accentColor = 0xFF085041;
}
