import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medi_vault/data/services/api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService.getToken', () {
    test('returns null when no token has been saved', () async {
      final token = await ApiService.getToken();
      expect(token, isNull);
    });

    test('returns the stored token after saveToken is called', () async {
      await ApiService.saveToken('my-jwt-token');
      final token = await ApiService.getToken();
      expect(token, 'my-jwt-token');
    });

    test('returns the last saved token when called multiple times', () async {
      await ApiService.saveToken('first-token');
      await ApiService.saveToken('second-token');
      final token = await ApiService.getToken();
      expect(token, 'second-token');
    });
  });

  group('ApiService.saveUser / getUser', () {
    test('getUser returns null when no user has been saved', () async {
      final user = await ApiService.getUser();
      expect(user, isNull);
    });

    test('saves and retrieves a patient user correctly', () async {
      final userData = {'id': 'user1', 'name': 'Alice', 'email': 'alice@test.com', 'role': 'patient'};
      await ApiService.saveUser(userData);

      final user = await ApiService.getUser();
      expect(user, isNotNull);
      expect(user!['id'], 'alice@test.com'.contains('@') ? 'user1' : null);
      expect(user['name'], 'Alice');
      expect(user['role'], 'patient');
    });

    test('saves and retrieves a doctor user correctly', () async {
      final userData = {'id': 'doc1', 'name': 'Dr. Bob', 'email': 'bob@hospital.com', 'role': 'doctor'};
      await ApiService.saveUser(userData);

      final user = await ApiService.getUser();
      expect(user, isNotNull);
      expect(user!['role'], 'doctor');
      expect(user['name'], 'Dr. Bob');
    });

    test('also saves role as a separate key for splash screen routing', () async {
      final prefs = await SharedPreferences.getInstance();
      await ApiService.saveUser({'id': 'u1', 'name': 'X', 'role': 'patient'});
      // role is stored as its own key so the SplashScreen can check it
      // without having to deserialise the whole user JSON blob
      expect(prefs.getString('role'), 'patient');
    });

    test('does not save role key when role field is absent', () async {
      final prefs = await SharedPreferences.getInstance();
      await ApiService.saveUser({'id': 'u1', 'name': 'X'});
      expect(prefs.getString('role'), isNull);
    });

    test('returns null when the stored user JSON is corrupted', () async {
      final prefs = await SharedPreferences.getInstance();
      // write garbage directly so we can test the parser's error recovery
      await prefs.setString('user', 'not-valid-json{{');

      final user = await ApiService.getUser();
      expect(user, isNull);
    });

    test('returns null when stored user is a JSON array instead of object', () async {
      final prefs = await SharedPreferences.getInstance();
      // valid JSON but wrong type - should be caught and treated as missing
      await prefs.setString('user', '[1, 2, 3]');

      final user = await ApiService.getUser();
      expect(user, isNull);
    });
  });

  group('ApiService.clearSession', () {
    test('removes token, user, and role from preferences', () async {
      // save everything first so there's something to clear
      final prefs = await SharedPreferences.getInstance();
      await ApiService.saveToken('tok');
      await ApiService.saveUser({'id': 'u1', 'name': 'X', 'role': 'patient'});

      await ApiService.clearSession();

      expect(await ApiService.getToken(), isNull);
      expect(await ApiService.getUser(), isNull);
      expect(prefs.getString('role'), isNull);
    });

    test('calling clearSession on an empty session is a no-op (no error)', () async {
      await expectLater(ApiService.clearSession(), completes);
    });

    test('after clearSession, saving a new token works correctly', () async {
      await ApiService.saveToken('old-token');
      await ApiService.clearSession();
      await ApiService.saveToken('new-token');

      expect(await ApiService.getToken(), 'new-token');
    });
  });

  group('ApiService.getHeaders', () {
    test('includes Content-Type and no Authorization when no token is saved', () async {
      final headers = await ApiService.getHeaders();

      expect(headers['Content-Type'], 'application/json');
      expect(headers.containsKey('Authorization'), false);
    });

    test('includes Authorization Bearer header when a token is saved', () async {
      await ApiService.saveToken('abc-token');
      final headers = await ApiService.getHeaders();

      expect(headers['Authorization'], 'Bearer abc-token');
      expect(headers['Content-Type'], 'application/json');
    });
  });
}
