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
  /// Base URL selector
  ///
  /// For Flutter Web + Docker backend:
  /// Always use localhost:8000
  static const String baseUrl = 'http://192.168.0.48:8000';

  // --- Auth (form.py backend uses /api/auth) ---
  // Backend login expects form-data (OAuth2PasswordRequestForm), not JSON.
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';

  // --- Forms ---
  static const String createForm = '/api/forms/create';
  static const String listForms = '/api/forms/';
  static String getForm(String id) => '/api/forms/$id';

  // --- Responses ---
  static const String submitResponse = '/api/responses/submit';
  static String getResponses(String formId) => '/api/responses/$formId';
  static String getAnalytics(String formId) =>
      '/api/responses/$formId/analytics';

  // --- Export ---
  static String exportExcel(String formId) =>
      '/api/export/$formId/excel';
  static String exportPdf(String formId) =>
      '/api/export/$formId/pdf';

  // --- Upload ---
  static const String uploadFile = '/api/upload/';
}