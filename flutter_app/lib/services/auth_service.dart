import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  final _api = ApiClient.instance;

  /// Backend returns {access_token, token_type}.
  /// Login uses form-data per OAuth2PasswordRequestForm.
  Future<String> login(String email, String password) async {
    final data = await _api.postForm(ApiConstants.login, {
      'username': email,
      'password': password,
    }) as Map<String, dynamic>;

    final token = data['access_token'] as String;
    _api.setAuthToken(token);
    return token;
  }

  Future<void> signup(String email, String password) async {
    await _api.post(ApiConstants.signup, body: {
      'email': email,
      'password': password,
    });
  }

  Future<String> loginWithGoogle(String idToken) async {
    final data = await _api.post(ApiConstants.googleLogin, body: {
      'id_token': idToken,
    }) as Map<String, dynamic>;

    final token = data['access_token'] as String;
    _api.setAuthToken(token);
    return token;
  }

  /// GET /api/users/profile — returns the backend profile for the logged-in user.
  Future<Map<String, dynamic>> getProfile() async {
    final res = await _api.get(ApiConstants.userProfile);
    return res as Map<String, dynamic>;
  }

  /// PUT /api/users/profile — updates full_name and/or avatar_url.
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final res = await _api.put(ApiConstants.userProfile, body: body)
        as Map<String, dynamic>;
    return res;
  }

  void logout() {
    _api.setAuthToken(null);
  }
}
