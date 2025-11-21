import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Custom ImageProvider that includes JWT authentication headers
class AuthenticatedImageProvider extends ImageProvider<AuthenticatedImageProvider> {
  final String url;
  final double scale;

  const AuthenticatedImageProvider(this.url, {this.scale = 1.0});

  @override
  Future<AuthenticatedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AuthenticatedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(AuthenticatedImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<AuthenticatedImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(AuthenticatedImageProvider key, ImageDecoderCallback decode) async {
    try {
      assert(key == this);

      // Get the JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // Build the full URL if it's a relative path
      final fullUrl = url.startsWith('http') 
          ? url 
          : 'http://localhost:8000$url';

      // Make authenticated request
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: Uri.parse(fullUrl),
        );
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Image file is empty');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is AuthenticatedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'AuthenticatedImageProvider')}("$url", scale: $scale)';
}
