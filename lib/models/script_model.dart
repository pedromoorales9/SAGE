class Script {
  final int id;
  final String filename;
  final String content;
  final DateTime uploadDate;
  final DateTime? modifiedDate;
  final DateTime? lastExecution;
  final int executionCount;
  final int downloads;
  final String uploadedBy;
  final List<String> tags;
  final bool isFavorite;

  const Script({
    required this.id,
    required this.filename,
    required this.content,
    required this.uploadDate,
    this.modifiedDate,
    this.lastExecution,
    required this.executionCount,
    required this.downloads,
    required this.uploadedBy,
    this.tags = const [],
    this.isFavorite = false,
  });

  String get extension => filename.contains('.')
      ? filename.substring(filename.lastIndexOf('.'))
      : '';

  factory Script.fromMap(Map<String, dynamic> map) {
    return Script(
      id: map['id'],
      filename: map['filename'],
      content: map['content'],
      uploadDate: DateTime.parse(map['upload_date']),
      modifiedDate: map['modified_date'] != null
          ? DateTime.parse(map['modified_date'])
          : null,
      lastExecution: map['last_execution'] != null
          ? DateTime.parse(map['last_execution'])
          : null,
      executionCount: map['execution_count'] ?? 0,
      downloads: map['downloads'] ?? 0,
      uploadedBy: map['uploaded_by'] ?? 'Unknown',
      tags: map['tags'] != null && map['tags'].toString().isNotEmpty
          ? map['tags'].toString().split(',')
          : [],
      isFavorite: map['is_favorite'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'content': content,
      'upload_date': uploadDate.toIso8601String(),
      'modified_date': modifiedDate?.toIso8601String(),
      'last_execution': lastExecution?.toIso8601String(),
      'execution_count': executionCount,
      'downloads': downloads,
      'uploaded_by': uploadedBy,
      'tags': tags.join(','),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  Script copyWith({
    int? id,
    String? filename,
    String? content,
    DateTime? uploadDate,
    DateTime? modifiedDate,
    DateTime? lastExecution,
    int? executionCount,
    int? downloads,
    String? uploadedBy,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Script(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      content: content ?? this.content,
      uploadDate: uploadDate ?? this.uploadDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      lastExecution: lastExecution ?? this.lastExecution,
      executionCount: executionCount ?? this.executionCount,
      downloads: downloads ?? this.downloads,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class ExecutionLog {
  final int id;
  final int scriptId;
  final String username;
  final DateTime executionDate;
  final bool success;
  final String? scriptName;
  final String? errorMessage;

  const ExecutionLog({
    required this.id,
    required this.scriptId,
    required this.username,
    required this.executionDate,
    required this.success,
    this.scriptName,
    this.errorMessage,
  });

  factory ExecutionLog.fromMap(Map<String, dynamic> map) {
    return ExecutionLog(
      id: map['id'],
      scriptId: map['script_id'],
      username: map['username'],
      executionDate: DateTime.parse(map['execution_date']),
      success: map['success'] == 1,
      scriptName: map['filename'],
      errorMessage: map['error_message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'script_id': scriptId,
      'username': username,
      'execution_date': executionDate.toIso8601String(),
      'success': success ? 1 : 0,
      'error_message': errorMessage,
    };
  }
}
