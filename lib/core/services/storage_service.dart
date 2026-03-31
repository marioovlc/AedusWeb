import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final String _cloudName = EnvConfig.cloudinaryCloudName;
  final String _apiKey = EnvConfig.cloudinaryApiKey;

  Future<String?> uploadFile(Uint8List fileBytes, String fileName, {bool isAudio = false}) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'ml_default' // Or a specific preset if configured
        ..fields['api_key'] = _apiKey
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));

      if (isAudio) {
        request.fields['resource_type'] = 'raw';
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
