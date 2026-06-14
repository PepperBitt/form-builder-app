// ---------------------------------------------------------------------------
// Data Models for Form Builder
// ---------------------------------------------------------------------------

enum FieldType {
  shortText,
  longText,
  email,
  number,
  multipleChoice,
  checkbox,
  rating,
  date,
  fileUpload,
}

extension FieldTypeExtension on FieldType {
  String get label {
    switch (this) {
      case FieldType.shortText:
        return 'Short Text';
      case FieldType.longText:
        return 'Long Text';
      case FieldType.email:
        return 'Email';
      case FieldType.number:
        return 'Number';
      case FieldType.multipleChoice:
        return 'Multiple Choice';
      case FieldType.checkbox:
        return 'Checkboxes';
      case FieldType.rating:
        return 'Rating Scale';
      case FieldType.date:
        return 'Date';
      case FieldType.fileUpload:
        return 'File Upload';
    }
  }

  String get iconCode {
    switch (this) {
      case FieldType.shortText:
        return 'text_fields';
      case FieldType.longText:
        return 'subject';
      case FieldType.email:
        return 'email';
      case FieldType.number:
        return 'pin';
      case FieldType.multipleChoice:
        return 'radio_button_checked';
      case FieldType.checkbox:
        return 'check_box';
      case FieldType.rating:
        return 'star';
      case FieldType.date:
        return 'calendar_today';
      case FieldType.fileUpload:
        return 'upload_file';
    }
  }
}

class FieldModel {
  final String id;
  FieldType type;
  String label;
  String helperText;
  bool isRequired;
  bool randomize;
  List<String> options;
  int maxRating;

  FieldModel({
    required this.id,
    required this.type,
    this.label = '',
    this.helperText = '',
    this.isRequired = false,
    this.randomize = false,
    this.options = const [],
    this.maxRating = 5,
  });

  FieldModel copyWith({
    String? id,
    FieldType? type,
    String? label,
    String? helperText,
    bool? isRequired,
    bool? randomize,
    List<String>? options,
    int? maxRating,
  }) {
    return FieldModel(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      helperText: helperText ?? this.helperText,
      isRequired: isRequired ?? this.isRequired,
      randomize: randomize ?? this.randomize,
      options: options ?? List.from(this.options),
      maxRating: maxRating ?? this.maxRating,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'label': label,
        'helperText': helperText,
        'isRequired': isRequired,
        'randomize': randomize,
        'options': options,
        'maxRating': maxRating,
      };
}

class FormModel {
  final String id;
  String title;
  String description;
  List<FieldModel> fields;
  bool isLive;
  int responseCount;
  String workspaceName;
  final DateTime createdAt;

  FormModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.fields,
    this.isLive = false,
    this.responseCount = 0,
    this.workspaceName = 'My Workspace',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'fields': fields.map((f) => f.toJson()).toList(),
        'isLive': isLive,
        'responseCount': responseCount,
        'workspaceName': workspaceName,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ResponseModel {
  final String id;
  final String formId;
  final Map<String, dynamic> data;
  final DateTime submittedAt;
  final String? respondentEmail;
  final String? location;

  ResponseModel({
    required this.id,
    required this.formId,
    required this.data,
    required this.submittedAt,
    this.respondentEmail,
    this.location,
  });
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

class UserSettingsModel {
  final bool emailNotifications;
  final bool pushNotifications;
  final String theme;
  final String language;

  const UserSettingsModel({
    this.emailNotifications = true,
    this.pushNotifications = false,
    this.theme = 'system',
    this.language = 'en',
  });

  UserSettingsModel copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    String? theme,
    String? language,
  }) {
    return UserSettingsModel(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      theme: theme ?? this.theme,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() => {
        'email_notifications': emailNotifications,
        'push_notifications': pushNotifications,
        'theme': theme,
        'language': language,
      };
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      notificationType: (json['notification_type'] ?? 'general') as String,
      isRead: (json['is_read'] ?? false) as bool,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ActivityItem {
  final String message;
  final String time;
  final String formName;
  final String? link;

  ActivityItem({
    required this.message,
    required this.time,
    required this.formName,
    this.link,
  });
}
