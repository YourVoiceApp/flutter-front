import 'package:http/http.dart' as http;

Future<List<int>?> readRecordingOutputImpl(String? pathOrBlobUrl) async {
  if (pathOrBlobUrl == null || pathOrBlobUrl.isEmpty) return null;
  final response = await http.get(Uri.parse(pathOrBlobUrl));
  if (response.statusCode != 200) return null;
  return response.bodyBytes;
}
