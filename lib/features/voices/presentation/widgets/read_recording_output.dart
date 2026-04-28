import 'read_recording_output_stub.dart'
    if (dart.library.io) 'read_recording_output_io.dart'
    if (dart.library.js_interop) 'read_recording_output_web.dart';

Future<List<int>?> readRecordingOutputBytes(String? pathOrBlobUrl) =>
    readRecordingOutputImpl(pathOrBlobUrl);
