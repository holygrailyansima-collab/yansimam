// ============================================
// File: lib/services/api/azure_face_service.dart
// Azure Face API Service - Face Detection with Relaxed Quality Control
// FIXED: Removed hardcoded API keys, using .env instead
// ============================================

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ EKLENDI

class AzureFaceService {
  // ✅ FIXED: Read from .env file (SECURE)
  final String _apiKey = dotenv.env['AZURE_FACE_API_KEY'] ?? '';
  final String _endpoint = dotenv.env['AZURE_FACE_API_ENDPOINT'] ?? 
      'https://yansimam-face-api.cognitiveservices.azure.com/';

  AzureFaceService() {
    // ✅ Validate that credentials are loaded
    if (_apiKey.isEmpty) {
      debugPrint('⚠️ WARNING: AZURE_FACE_API_KEY not found in .env file!');
    }
    if (_endpoint.isEmpty) {
      debugPrint('⚠️ WARNING: AZURE_FACE_API_ENDPOINT not found in .env file!');
    }
  }

  /// Validate face in image (DETECTION ONLY - Relaxed Quality)
  /// 
  /// Returns a Map with:
  /// - isValid: bool
  /// - message: String
  /// - faceCount: int
  /// - warnings: List of String
  Future<Map<String, dynamic>> validateFace(File imageFile) async {
    try {
      // ✅ Check if API key is configured
      if (_apiKey.isEmpty) {
        return {
          'isValid': false,
          'message': '❌ Azure API anahtarı yapılandırılmamış. .env dosyasını kontrol edin.',
          'faceCount': 0,
          'warnings': [],
        };
      }

      debugPrint('🔍 Azure Face API: Validating face...');

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // API endpoint for face detection (NO IDENTIFICATION)
      final url = Uri.parse(
        '$_endpoint/face/v1.0/detect?returnFaceId=false&returnFaceLandmarks=false&returnFaceAttributes=blur,exposure,noise',
      );

      // Make API request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Ocp-Apim-Subscription-Key': _apiKey,
        },
        body: bytes,
      );

      debugPrint('📡 Azure Response Status: ${response.statusCode}');
      debugPrint('📡 Azure Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> faces = json.decode(response.body);
        final List<String> warnings = [];

        // ❌ CRITICAL: No face detected
        if (faces.isEmpty) {
          return {
            'isValid': false,
            'message': '❌ Yüz algılanamadı. Lütfen net bir profil fotoğrafı çekin.',
            'faceCount': 0,
            'warnings': [],
          };
        }

        // ❌ CRITICAL: Multiple faces
        if (faces.length > 1) {
          return {
            'isValid': false,
            'message': '❌ Birden fazla yüz tespit edildi. Lütfen sadece sizin olduğunuz bir fotoğraf seçin.',
            'faceCount': faces.length,
            'warnings': [],
          };
        }

        // ✅ Single face detected - Check quality (WARNINGS ONLY)
        final face = faces[0];
        final attributes = face['faceAttributes'];

        // Check blur (WARNING - Not blocking)
        if (attributes != null && attributes['blur'] != null) {
          final blur = attributes['blur'];
          final blurLevel = blur['blurLevel'];
          if (blurLevel == 'high') {
            warnings.add('⚠️ Fotoğraf biraz bulanık. Mümkünse daha net bir fotoğraf kullanın.');
          }
        }

        // Check exposure (WARNING - Not blocking)
        if (attributes != null && attributes['exposure'] != null) {
          final exposure = attributes['exposure'];
          final exposureLevel = exposure['exposureLevel'];
          if (exposureLevel == 'overExposure') {
            warnings.add('⚠️ Fotoğraf biraz parlak. Daha iyi aydınlatmada deneyin.');
          } else if (exposureLevel == 'underExposure') {
            warnings.add('⚠️ Fotoğraf biraz karanlık. Daha iyi aydınlatmada deneyin.');
          }
        }

        // Check noise (WARNING - Not blocking)
        if (attributes != null && attributes['noise'] != null) {
          final noise = attributes['noise'];
          final noiseLevel = noise['noiseLevel'];
          if (noiseLevel == 'high') {
            warnings.add('⚠️ Fotoğraf kalitesi düşük. Daha kaliteli bir kamerayla deneyin.');
          }
        }

        // All checks passed (even with warnings)
        debugPrint('✅ Face validation successful');
        String message = '✅ Fotoğraf doğrulandı! Yüzünüz başarıyla tespit edildi.';
        
        if (warnings.isNotEmpty) {
          message += '\n\n${warnings.join('\n')}';
        }

        return {
          'isValid': true,
          'message': message,
          'faceCount': 1,
          'warnings': warnings,
          'faceRectangle': face['faceRectangle'],
          'faceAttributes': attributes,
        };
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        return {
          'isValid': false,
          'message': '❌ Geçersiz fotoğraf formatı: ${error['error']['message']}',
          'faceCount': 0,
          'warnings': [],
        };
      } else if (response.statusCode == 401) {
        return {
          'isValid': false,
          'message': '❌ Azure API anahtarı geçersiz',
          'faceCount': 0,
          'warnings': [],
        };
      } else if (response.statusCode == 403) {
        final errorBody = json.decode(response.body);
        debugPrint('🔴 403 Error: $errorBody');
        return {
          'isValid': false,
          'message': '❌ Azure API erişim hatası. Lütfen API ayarlarını kontrol edin.',
          'faceCount': 0,
          'warnings': [],
        };
      } else {
        return {
          'isValid': false,
          'message': '❌ Azure API hatası: ${response.statusCode}',
          'faceCount': 0,
          'warnings': [],
        };
      }
    } catch (e) {
      debugPrint('❌ Azure Face API Error: $e');
      return {
        'isValid': false,
        'message': '❌ Bağlantı hatası: $e',
        'faceCount': 0,
        'warnings': [],
      };
    }
  }

  /// Detect face (backward compatibility)
  static Future<Map<String, dynamic>> detectFace(File imageFile) async {
    final service = AzureFaceService();
    final result = await service.validateFace(imageFile);
    
    return {
      'success': result['isValid'],
      'error': result['isValid'] ? null : result['message'],
    };
  }

  /// Validate image quality (backward compatibility)
  static Future<bool> validateImageQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Minimum 10KB file size check
      if (bytes.length < 10000) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Image quality validation error: $e');
      return false;
    }
  }
}
