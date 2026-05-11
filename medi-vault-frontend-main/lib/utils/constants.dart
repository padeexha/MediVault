class Constants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://medivault-ejaa.onrender.com/api',
  );

  static const String registerPatient = '$baseUrl/auth/register/patient';
  static const String registerDoctor = '$baseUrl/auth/register/doctor';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String resendOtp = '$baseUrl/auth/resend-otp';
  static const String getProfile = '$baseUrl/auth/profile';
  static const String updateProfile = '$baseUrl/auth/profile';

  static const String records = '$baseUrl/records';
  static const String uploadRecord = '$baseUrl/records/upload';
  static const String search = '$baseUrl/search';
  static const String searchDoctor = '$baseUrl/auth/search-doctor';
  static const String doctors = '$baseUrl/auth/doctors';

  static const String permissions = '$baseUrl/permissions';
  static const String grantPermission = '$baseUrl/permissions/grant';
  static const String myDoctors = '$baseUrl/permissions/my-doctors';
  static const String sharedWithMe = '$baseUrl/permissions/shared-with-me';

  static const String auditLogs = '$baseUrl/audit/my-logs';
}
