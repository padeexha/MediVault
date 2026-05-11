import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class GoogleAuthService {
  static final _googleSignIn = GoogleSignIn(
    serverClientId: 'YOUR_WEB_CLIENT_ID', // Replace with your Google Web Client ID
    scopes: ['email', 'profile'],
  );

  static Future<Map<String, dynamic>> signIn({required String role}) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return {'success': false, 'message': 'Sign-in cancelled'};

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return {'success': false, 'message': 'Failed to get ID token'};

      final response = await ApiService.post(Constants.googleAuth, {
        'id_token': idToken,
        'role': role,
      });

      if (response['success'] == true) {
        await ApiService.saveToken(response['token']);
        await ApiService.saveUser(response['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('role', response['user']['role']);
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Google sign-in failed: ${e.toString()}'};
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
