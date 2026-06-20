import 'dart:convert';

import '../storage/token_storage.dart';

class CurrentUserService {
  CurrentUserService(this._tokenStorage);

  final TokenStorage _tokenStorage;

  String? _cachedToken;
  String? _cachedUserId;

  Future<String?> currentUserId() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      _cachedToken = null;
      _cachedUserId = null;
      return null;
    }
    if (token == _cachedToken) return _cachedUserId;

    _cachedToken = token;
    _cachedUserId = _extractSub(token);
    return _cachedUserId;
  }

  Future<List<String>> currentRoles() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return const [];
    return rolesFromToken(token);
  }

  static String? _extractSub(String jwt) {
    final map = _decodePayload(jwt);
    if (map == null) return null;
    final sub = map['sub'] ?? map['nameid'] ?? map['userId'];
    return sub?.toString();
  }

  static List<String> rolesFromToken(String jwt) {
    final map = _decodePayload(jwt);
    if (map == null) return const [];
    final claim = map['role'] ??
        map['roles'] ??
        map['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    if (claim == null) return const [];
    if (claim is String) return [claim];
    if (claim is List) return claim.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, dynamic>? _decodePayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return null;
      return map;
    } catch (_) {
      return null;
    }
  }
}
