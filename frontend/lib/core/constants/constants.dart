class Constants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://medivault-ejaa.onrender.com/api',
  );

  static const String registerPatient = '$baseUrl/auth/register/patient';
  static const String registerDoctor  = '$baseUrl/auth/register/doctor';
  static const String login           = '$baseUrl/auth/login';
  static const String logout          = '$baseUrl/auth/logout';
  static const String forgotPassword  = '$baseUrl/auth/forgot-password';
  static const String resendVerification   = '$baseUrl/auth/resend-verification';
  static const String getProfile           = '$baseUrl/auth/profile';
  static const String updateProfile        = '$baseUrl/auth/profile';
  static const String updateProfilePicture = '$baseUrl/auth/profile/picture';

  static const String records      = '$baseUrl/records';
  static const String uploadRecord = '$baseUrl/records/upload';
  static const String search       = '$baseUrl/search';
  static const String searchDoctor = '$baseUrl/auth/search-doctor';
  static const String doctors      = '$baseUrl/auth/doctors';

  static const String permissions     = '$baseUrl/permissions';
  static const String grantPermission = '$baseUrl/permissions/grant';
  static const String myDoctors       = '$baseUrl/permissions/my-doctors';
  static const String sharedWithMe    = '$baseUrl/permissions/shared-with-me';

  static const String changePassword = '$baseUrl/auth/change-password';

  static const String auditLogs = '$baseUrl/audit/my-logs';

  // Health Profile
  static const String healthProfileMyProfile     = '$baseUrl/health-profile/my-profile';
  static const String healthProfileSave          = '$baseUrl/health-profile/save';
  static const String healthProfileRequestAccess = '$baseUrl/health-profile/request-access';
  static const String healthProfileGrantAccess   = '$baseUrl/health-profile/grant-access';
  static const String healthProfileMyAccess      = '$baseUrl/health-profile/my-access';
  static String healthProfileApprove(String id)  => '$baseUrl/health-profile/approve/$id';
  static String healthProfileReject(String id)   => '$baseUrl/health-profile/reject/$id';
  static String healthProfileRevoke(String id)   => '$baseUrl/health-profile/revoke/$id';
  static String healthProfileView(String patId)  => '$baseUrl/health-profile/view/$patId';
}
