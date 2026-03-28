/// Model for media pending upload/sync
/// 
/// Used to track images or videos that need to be uploaded to the server.
/// Supports offline saving with sync status (US15).
class PendingMedia {
  /// Unique identifier for the media item.
  final String id;
  
  /// Local file path to the media file.
  final String filePath;
  
  /// Type of media: 'video' or 'image'.
  final String fileType; 
  
  /// Optional voice transcription associated with the media.
  final String? voiceTranscription;
  
  /// Duration of the media in seconds (mostly for video).
  final int durationSeconds;
  
  /// Timestamp when the media was created/captured.
  final int createdAt;
  
  /// Base64 encoded content of the media.
  /// Used for web persistence (US15).
  final String? base64Content; 
  
  /// Indicates if the media has been successfully synced to the server.
  final bool isSynced;

  /// Creates a [PendingMedia] instance.
  PendingMedia({
    required this.id,
    required this.filePath,
    required this.fileType,
    this.voiceTranscription,
    this.durationSeconds = 0,
    required this.createdAt,
    this.isSynced = false,
    this.base64Content,
  });

  /// Create a copy of the instance with updated fields.
  /// 
  /// Useful for immutable state updates.
  PendingMedia copyWith({
    String? id,
    String? filePath,
    String? fileType,
    String? voiceTranscription,
    int? durationSeconds,
    int? createdAt,
    bool? isSynced,
    String? base64Content,
  }) {
    return PendingMedia(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      voiceTranscription: voiceTranscription ?? this.voiceTranscription,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      base64Content: base64Content ?? this.base64Content,
    );
  }

  /// Converts the [PendingMedia] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileType': fileType,
      'voiceTranscription': voiceTranscription,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt,
      'isSynced': isSynced,
      'base64Content': base64Content,
    };
  }

  /// Creates a [PendingMedia] instance from a JSON map.
  factory PendingMedia.fromJson(Map<String, dynamic> json) {
    return PendingMedia(
      id: json['id'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      voiceTranscription: json['voiceTranscription'],
      durationSeconds: json['durationSeconds'] ?? 0,
      createdAt: json['createdAt'],
      isSynced: json['isSynced'] ?? false,
      base64Content: json['base64Content'],
    );
  }
}
