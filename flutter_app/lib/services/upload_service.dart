import '../core/network/api_client.dart';
import '../api_services/api_constants.dart';

/// Result returned after a successful file upload.
class UploadResult {
  /// Original file name provided by the user.
  final String filename;

  /// UUID-based name the backend stored the file as.
  final String storedName;

  /// Relative URL to access the file (e.g. `/files/uuid.pdf`).
  final String url;

  const UploadResult({
    required this.filename,
    required this.storedName,
    required this.url,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      filename: json['filename'] as String,
      storedName: json['stored_name'] as String,
      url: json['url'] as String,
    );
  }

  /// Absolute URL to the file on the backend server.
  String get absoluteUrl => '${ApiConstants.baseUrl}$url';
}

/// Service that handles file uploads to the backend.
class UploadService {
  final _api = ApiClient.instance;

  /// Uploads a file and returns the [UploadResult].
  ///
  /// Provide either [filePath] (mobile/desktop) or [fileBytes] (web).
  /// [fileName] is always required for the multipart request.
  Future<UploadResult> uploadFile({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
  }) async {
    final res = await _api.uploadFile(
      ApiConstants.uploadFile,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    return UploadResult.fromJson(res);
  }
}
