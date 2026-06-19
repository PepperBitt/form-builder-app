/// All backend API endpoints.
///
/// IMPORTANT: `baseUrl` must match where your FastAPI backend is running.
///
/// Supported environments:
/// - Running locally on same machine:       http://localhost:8000
/// - Android emulator hitting host machine: http://10.0.2.2:8000
/// - Physical phone on same WiFi:           http://<your-pc-ip>:8000
/// - Dockerized backend (Flutter Web):      http://localhost:8000
/// - Deployed server:                       https://your-domain.com
///
/// NOTE:
/// Flutter Web runs inside the browser, not inside the Docker container.
/// So API requests must target localhost instead of Docker service names
/// like `backend:8000`.
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String googleClientId =
      'your-google-oauth-client-id.apps.googleusercontent.com';

  /// Google Sign-In client ID for web and iOS/macOS.
  /// On Android, the plugin typically uses native app credentials and SHA-1
  /// configuration instead of an explicit client ID.
  static bool get googleClientIdConfigured {
    return googleClientId.isNotEmpty &&
        !googleClientId.contains('your-google-oauth-client-id');
  }

  /// Public frontend base URL used for share links.
  /// On Flutter Web, prefer Uri.base.origin at runtime.
  /// On Android/iOS/desktop this constant is used as the fallback.
  static const String publicFrontendBaseUrl = 'http://localhost:3000';

  // --- Auth (form.py backend uses /api/auth) ---
  // Backend login expects form-data (OAuth2PasswordRequestForm), not JSON.
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String googleLogin = '/api/auth/google';

  // --- Users / Profile ---
  static const String userProfile = '/api/users/profile';
  static const String userSettings = '/api/users/settings';
  static const String userAnalytics = '/api/users/analytics';
  static const String userForms = '/api/users/me/forms';

  // --- Forms ---
  static const String createForm = '/api/forms/create';

  /// GET /api/forms/ — all published (live) forms (public, no auth required)
  static const String publicForms = '/api/forms/';

  /// GET /api/forms/{id}
  static String getForm(String id) => '/api/forms/$id';

  /// PUT /api/forms/{id}
  static String updateForm(String id) => '/api/forms/$id';

  /// DELETE /api/forms/{id}
  static String deleteForm(String id) => '/api/forms/$id';

  /// POST /api/forms/{id}/publish
  static String publishForm(String id) => '/api/forms/$id/publish';

  /// POST /api/forms/{id}/unpublish
  static String unpublishForm(String id) => '/api/forms/$id/unpublish';

  // --- Responses ---
  static const String submitResponse = '/api/responses/submit';
  static String getResponses(String formId) => '/api/responses/$formId';
  static String getAnalytics(String formId) =>
      '/api/responses/$formId/analytics';

  // --- Notifications ---
  static const String notifications = '/api/notifications';
  static const String markNotificationsRead = '/api/notifications/read';

  // --- Export ---
  static String exportJson(String formId) => '/api/export/$formId/json';
  static String exportCsv(String formId) => '/api/export/$formId/csv';
  static String exportPdf(String formId) => '/api/export/$formId/pdf';
  static String exportExcel(String formId) => '/api/export/$formId/excel';

  // --- Upload ---
  static const String uploadFile = '/api/upload/';
}
