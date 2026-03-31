import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final String _cloudName = EnvConfig.cloudinaryCloudName;
  final String _apiKey = EnvConfig.cloudinaryApiKey;
  final String _apiSecret = EnvConfig.cloudinaryApiSecret;

  Future<String?> uploadFile(Uint8List fileBytes, String fileName, {bool isAudio = false}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // For audio, we'll use 'auto' or 'video'. Actually Cloudinary recommends 'video' for audio.
      
      final params = <String, String>{
        'timestamp': timestamp.toString(),
      };
      
      if (isAudio) {
        params['resource_type'] = 'video'; // Audio as video
      }

      final signature = _generateSignature(params, _apiSecret);
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/${isAudio ? 'video' : 'image'}/upload');
      
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ));

      if (isAudio) {
        request.fields['resource_type'] = 'video';
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

  String _generateSignature(Map<String, String> params, String secret) {
    // Sort keys alphabetically
    final sortedKeys = params.keys.toList()..sort();
    
    // Create query string: param1=value1&param2=value2
    final queryString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Append API Secret and hash with SHA1
    final signatureString = '$queryString$secret';
    return sha1.convert(utf8.encode(signatureString)).toString();
  }
}
