part of receive_sharing_intent;

class SharedMediaFile {
  /// Shared file path, url or the text
  /// NOTE. All files are copied to a temp cache folder
  final String path;

  /// Video thumbnail
  final String? thumbnail;

  /// Video duration in milliseconds
  final int? duration;

  /// Shared media type
  final SharedMediaType type;

  /// Mime type of the file.
  /// i.e. image/jpeg, video/mp4, text/plain
  final String? mimeType;

  /// Post message iOS ONLY
  final String? message;

  SharedMediaFile({
    required this.path,
    required this.type,
    this.thumbnail,
    this.duration,
    this.mimeType,
    this.message,
  });

  SharedMediaFile.fromMap(Map<String, dynamic> json)
      : path = json['path'],
        thumbnail = json['thumbnail'],
        duration = json['duration'],
        type = SharedMediaType.fromValue(json['type']),
        mimeType = json['mimeType'],
        message = json['message'];

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'thumbnail': thumbnail,
      'duration': duration,
      'type': type.value,
      'mimeType': mimeType,
      'message': message,
    };
  }
}

enum SharedMediaType {
  image('image'),
  video('video'),
  text('text'),
  file('file'),
  pdf('pdf'),
  url('url');

  final String value;

  const SharedMediaType(this.value);

  static SharedMediaType fromValue(String value) {
    return SharedMediaType.values.firstWhere((e) => e.value == value);
  }
}
