import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/api_constants.dart';
import '../core/models.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: _resolveGoogleClientId(),
    serverClientId: _resolveGoogleClientId(),
  );

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      // Fetch real profile from backend instead of deriving from email.
      await _fetchProfile(fallbackEmail: email);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signup(email, password);
      // Auto-login after successful signup
      await _authService.login(email, password);
      // Fetch real profile (name may not be set yet, so use provided name as
      // fallback until the user saves their profile).
      await _fetchProfile(fallbackEmail: email, fallbackName: name);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if ((kIsWeb ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS) &&
          !_isGoogleClientIdConfigured) {
        throw Exception(
          'Google sign-in is not configured. Set ApiConstants.googleClientId in flutter_app/lib/core/constants/api_constants.dart.',
        );
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in did not return an ID token.');
      }

      await _authService.loginWithGoogle(idToken);
      await _fetchProfile(
        fallbackEmail: account.email,
        fallbackName: account.displayName,
      );

      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh profile data from the backend (e.g. after editing on ProfileScreen).
  Future<void> refreshProfile() async {
    try {
      await _fetchProfile(fallbackEmail: _currentUser?.email ?? '');
      notifyListeners();
    } catch (_) {
      // Silently ignore refresh failures — UI keeps showing cached data.
    }
  }

  /// Update full_name and/or avatar_url on the backend, then refresh local model.
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _authService.updateProfile(
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
      _currentUser = UserModel(
        id: (res['id'] ?? _currentUser?.id ?? '') as String,
        name: (res['full_name'] ?? _currentUser?.name ?? '') as String,
        email: (res['email'] ?? _currentUser?.email ?? '') as String,
        avatarUrl: (res['avatar_url'] ?? _currentUser?.avatarUrl) as String?,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _authService.logout();
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  static String? _resolveGoogleClientId() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return ApiConstants.googleClientId;
    }
    return null;
  }

  static bool get _isGoogleClientIdConfigured {
    return ApiConstants.googleClientIdConfigured;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _fetchProfile({
    required String fallbackEmail,
    String? fallbackName,
  }) async {
    try {
      final profile = await _authService.getProfile();
      final rawName = profile['full_name'];
      final name = (rawName is String && rawName.isNotEmpty)
          ? rawName
          : (fallbackName ?? fallbackEmail.split('@').first);
      _currentUser = UserModel(
        id: (profile['id'] ?? fallbackEmail) as String,
        name: name,
        email: (profile['email'] ?? fallbackEmail) as String,
        avatarUrl: profile['avatar_url'] as String?,
      );
    } catch (_) {
      // If profile fetch fails, fall back to minimal local model.
      _currentUser ??= UserModel(
        id: fallbackEmail,
        name: fallbackName ?? fallbackEmail.split('@').first,
        email: fallbackEmail,
      );
    }
  }
}
