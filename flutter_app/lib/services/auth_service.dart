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

  void logout() {
    _api.setAuthToken(null);
  }
}
