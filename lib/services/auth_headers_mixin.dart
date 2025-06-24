import 'package:flutter_secure_storage/flutter_secure_storage.dart';

mixin AuthHeadersMixin {
  static const _storage = FlutterSecureStorage();
  static const _keyAccessToken = 'ACCESS_TOKEN';

  /// Restituisce headers per chiamate HTTP protette
  Future<Map<String,String>> authHeaders() async {
    final token = await _storage.read(key: _keyAccessToken);
    if (token == null) {
      throw Exception('Non autenticato');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}