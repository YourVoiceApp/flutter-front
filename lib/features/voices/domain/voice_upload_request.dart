import 'dart:typed_data';

class VoiceUploadRequest {
  const VoiceUploadRequest({
    required this.filename,
    required this.bytes,
    required this.folderId,
    required this.name,
    this.description,
  });

  final String filename;
  final Uint8List bytes;
  final String folderId;
  final String name;
  final String? description;
}
