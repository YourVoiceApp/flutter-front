import 'dart:io';

Future<List<int>?> readRecordingOutputImpl(String? pathOrBlobUrl) async {
  if (pathOrBlobUrl == null || pathOrBlobUrl.isEmpty) return null;
  final file = File(pathOrBlobUrl);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
