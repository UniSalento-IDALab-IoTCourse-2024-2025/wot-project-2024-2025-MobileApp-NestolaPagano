import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import '../exceptions/registration_exception.dart';
import '../models/user.dart';
import 'auth_headers_mixin.dart';

class AuthService with ChangeNotifier, AuthHeadersMixin {
  static const _storage = FlutterSecureStorage();
  static const _baseUrl = 'http://192.168.254.37:8000/api/auth';

  static const _keyAccessToken  = 'ACCESS_TOKEN';
  static const _keyRefreshToken = 'REFRESH_TOKEN';

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Se l'utente è già loggato (access_token e refresh_token in memoria),
  /// prova a caricare il profilo dal token e a rinnovare l'access token se necessario.
  Future<void> tryAutoLogin() async {
    final at = await _storage.read(key: _keyAccessToken);
    final rt = await _storage.read(key: _keyRefreshToken);
    if (at == null || rt == null) return;

    if (Jwt.isExpired(at)) {
      final success = await refreshAccessToken();
      if (!success) return;
    }
    await fetchCurrentUser();
  }

  Future<User?> register({
    required String email,
    required String password,
    required String full_name,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/register');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'full_name': full_name.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final userJson     = data['user'] as Map<String, dynamic>;
        final accessToken  = data['access_token']  as String;
        final refreshToken = data['refresh_token'] as String;

        await _storage.write(key: _keyAccessToken, value: accessToken);
        await _storage.write(key: _keyRefreshToken, value: refreshToken);

        _currentUser = User.fromJson(userJson);
        notifyListeners();
        print("Registration successful! Response: ${response.body}");
        print("User: ${User.fromJson(userJson)}");
        return _currentUser;
      }

      if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        final msg = body['detail'] is String
            ? body['detail'] as String
            : 'Dati non validi. Controlla i campi.';
        throw RegistrationException(msg);
      }

      if (response.statusCode == 422) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body.containsKey('detail') && body['detail'] is List) {
          final errors = (body['detail'] as List).map((e) {
            if (e is Map<String, dynamic> && e.containsKey('msg')) {
              return e['msg'];
            }
            return null;
          }).whereType<String>().toList();
          if (errors.isNotEmpty) {
            throw RegistrationException(errors.join('\n'));
          }
        }
        throw RegistrationException('Formato dati errato.');
      }

      if (response.statusCode >= 500) {
        throw RegistrationException('Errore interno del server. Riprova più tardi.');
      }

      throw RegistrationException(
        'Registrazione fallita (codice ${response.statusCode}). Riprova.',
      );
    } on RegistrationException {
      rethrow;
    } catch (e) {
      throw RegistrationException('Connessione impossibile: controlla la rete.');
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        print("Login successful! Response: ${response.body}");
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final userJson     = data['user'] as Map<String, dynamic>;
        final accessToken  = data['access_token']  as String;
        final refreshToken = data['refresh_token'] as String;

        await _storage.write(key: _keyAccessToken,  value: accessToken);
        await _storage.write(key: _keyRefreshToken, value: refreshToken);

        _currentUser = User.fromJson(userJson);
        notifyListeners();
        return true;
      } else {
        print("Login failed. Status: ${response.statusCode}, Body: ${response.body}");
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final headers = await authHeaders();
    final uri = Uri.parse('$_baseUrl/change_password');
    final resp = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    return resp.statusCode == 200;
  }

  Future<bool> refreshAccessToken() async {
    try {
      final rt = await _storage.read(key: _keyRefreshToken);
      if (rt == null) return false;

      final uri = Uri.parse('$_baseUrl/refresh');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken  = data['access_token']  as String;
        final newRefreshToken = (data.containsKey('refresh_token'))
            ? (data['refresh_token'] as String)
            : rt;

        await _storage.write(key: _keyAccessToken,  value: newAccessToken);
        await _storage.write(key: _keyRefreshToken, value: newRefreshToken);

        await fetchCurrentUser();
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<String?> getValidAccessToken() async {
    final at = await _storage.read(key: _keyAccessToken);
    if (at == null) return null;

    if (Jwt.isExpired(at)) {
      final success = await refreshAccessToken();
      if (!success) return null;
      return await _storage.read(key: _keyAccessToken);
    }

    return at;
  }

  Future<bool> fetchCurrentUser() async {
    final headers = await authHeaders();
    final uri = Uri.parse('$_baseUrl/me');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      final userJson = jsonDecode(resp.body) as Map<String, dynamic>;
      _currentUser = User.fromJson(userJson);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    _currentUser = null;
    notifyListeners();
  }
}