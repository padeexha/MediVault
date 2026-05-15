import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Stores the user JSON blob and also writes the role separately so
  // the splash screen can read it without decoding the whole user object.
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
    if (user['role'] != null) {
      await prefs.setString('role', user['role'].toString());
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    try {
      final decoded = jsonDecode(userStr);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('role');
  }

  // Safely decodes the HTTP response body. Returns a consistent error map
  // if the body is malformed or not JSON so callers don't need to handle exceptions.
  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected server response', 'statusCode': response.statusCode};
    } catch (_) {
      return {
        'success': false,
        'message': 'Server error (${response.statusCode}). Please try again.',
        'statusCode': response.statusCode,
      };
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> delete(String url) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(Uri.parse(url), headers: headers);
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sends a multipart POST with the file and any additional form fields.
  // The Content-Type is derived from the file extension rather than relying
  // on the platform's mime-type lookup, which isn't available on all targets.
  static Future<Map<String, dynamic>> uploadFile(
    String url,
    File file,
    Map<String, String> fields,
  ) async {
    try {
      final token = await getToken();
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      fields.forEach((key, value) => request.fields[key] = value);

      final extension = file.path.split('.').last.toLowerCase();
      String contentType;
      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: Uri.file(file.path).pathSegments.last,
          contentType: MediaType.parse(contentType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
