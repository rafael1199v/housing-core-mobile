import '../auth/credentials.dart';
import '../storage/token_storage.dart';
import 'app_role.dart';
import 'role_api.dart';

class RoleService {
  RoleService({
    required RoleApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final RoleApi _api;
  final TokenStorage _tokenStorage;

  Future<Credentials> acquireRole(AppRole role) async {
    final credentials = await _api.assignRole(role);
    await _tokenStorage.saveTokens(
      accessToken: credentials.accessToken,
      refreshToken: credentials.refreshToken,
    );
    return credentials;
  }
}
