import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'authenticated_api_service.dart';

class UploadService {
  static final Dio _dio = Dio();

  /// Step 1 — Ask Django for a presigned PUT URL
  static Future<Map<String, dynamic>> getPresignedUrl({
    required String filename,
    required String challengeId,
  }) async {
    final payload = {'filename': filename, 'challenge_id': challengeId};
    print("➡️ Sending to /api/presign/: $payload");

    final response = await AuthenticatedApiService.authenticatedPost(
      '/api/presign/',
      payload,
    );

    print("⬅️ Response status: ${response.statusCode}");
    print("⬅️ Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('❌ Failed to get presigned URL: ${response.statusCode}');
    }

    final decoded = Map<String, dynamic>.from(jsonDecode(response.body));
    print("✅ Presigned URL received: ${decoded['presigned_url']}");
    return decoded;
  }

  /// Step 2 — Upload the file to Backblaze using presigned PUT URL
  static Future<void> uploadToBackblaze({
    required String presignedUrl,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      print("➡️ Uploading to Backblaze: $presignedUrl");

      final response = await _dio.put(
        presignedUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
          },
          validateStatus: (_) => true,
        ),
      );

      print("⬅️ Upload response status: ${response.statusCode}");
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        print("✅ Upload succeeded");
      } else {
        throw Exception(
          'Upload failed with status: ${response.statusCode}, body: ${response.data}',
        );
      }
    } catch (e, stack) {
      print("❌ Exception during upload: $e");
      print(stack);
      rethrow;
    }
  }

  /// Step 3 — Inform backend of the new file
  static Future<void> registerUpload({
    required String fileUrl,
    required String challengeId,
  }) async {
    try {
      print("➡️ Registering upload with backend: $fileUrl");
      final response = await AuthenticatedApiService.authenticatedPost(
        '/api/proofs/',
        {'challenge': challengeId, 'image_url': fileUrl},
      );

      print("⬅️ Register response status: ${response.statusCode}");
      if (response.statusCode == 201) {
        print("✅ Upload registered successfully in backend");
      } else {
        throw Exception('Failed to register upload: ${response.statusCode}');
      }
    } catch (e, stack) {
      print("❌ Exception during registerUpload: $e");
      print(stack);
      rethrow;
    }
  }

  /// Full pipeline: presign → upload → register
  static Future<void> uploadProof({
    required Uint8List bytes,
    required String filename,
    required String challengeId,
    String contentType = 'image/jpeg',
  }) async {
    print("🔹 Starting upload pipeline for $filename");
    try {
      final presignData = await getPresignedUrl(
        filename: filename,
        challengeId: challengeId,
      );

      final presignedUrl = presignData['presigned_url'] as String;
      final fileUrl = presignData['file_url'] as String;

      await uploadToBackblaze(
        presignedUrl: presignedUrl,
        bytes: bytes,
        contentType: contentType,
      );

      await registerUpload(fileUrl: fileUrl, challengeId: challengeId);

      print("✅ Upload pipeline completed successfully for $filename");
    } catch (e, stack) {
      print("❌ Upload pipeline failed for $filename: $e");
      print(stack);
      rethrow;
    }
  }
}
