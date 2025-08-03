import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:difychatbot/models/n8n_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';

class PromptApiService {
  final String n8nUrl = dotenv.env['N8N_URL_PROD'].toString();
  // final String n8nUrl = dotenv.env['N8N_TSEL_URL_DEV'].toString();

  // Helper method to get file bytes with fallback
  Future<List<int>?> _getFileBytes(PlatformFile file) async {
    // First try to get bytes directly from PlatformFile
    if (file.bytes != null) {
      return file.bytes!;
    }

    // Fallback: try to read from file path (mainly for Android/iOS)
    if (file.path != null) {
      try {
        final fileObj = File(file.path!);
        if (await fileObj.exists()) {
          return await fileObj.readAsBytes();
        }
      } catch (e) {
        print('Error reading file from path: $e');
      }
    }

    print('Unable to get file bytes from either bytes or path');
    return null;
  }

  Future<N8NModels?> postPrompt({String? message}) async {
    final url = Uri.parse(n8nUrl);
    final token = await _getToken();
    if (token == null) {
      return null; // Token tidak ditemukan
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      // print('Response from MURNI N8N: ${response}');
      if (response.statusCode == 200) {
        final n8nResponse = N8NModels.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
        // print('Response from N8N: ${n8nResponse.response}');
        return n8nResponse;
      } else {
        return null;
      }
    } catch (e) {
      print('terjadi kesalahan: $e');
      return null;
    }
  }

  // New method to handle different AI models with appropriate request body
  Future<N8NModels?> postPromptWithModel({
    required String model,
    String? prompt,
    PlatformFile? file,
  }) async {
    final url = Uri.parse(n8nUrl);
    final token = await _getToken();
    if (token == null) {
      return null; // Token tidak ditemukan
    }

    try {
      Map<String, dynamic> requestBody = {
        'model': model,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add request body fields based on model type
      switch (model) {
        case 'TSEL-Chatbot':
          // Send prompt only
          requestBody['prompt'] = prompt ?? '';
          break;

        case 'TSEL-Learning-Based':
          // Send PDF only
          if (file != null) {
            print('Processing file for TSEL Learning Based:');
            print('- File name: ${file.name}');
            print('- File size: ${file.size}');
            print('- File path: ${file.path}');

            // Try to get file bytes with fallback
            List<int>? fileBytes = await _getFileBytes(file);
            print('- File bytes available: ${fileBytes != null}');
            print('- File bytes length: ${fileBytes?.length ?? 0}');

            String? base64Data;
            if (fileBytes != null) {
              base64Data = base64Encode(fileBytes);
              print('- Base64 encoded length: ${base64Data.length}');
              print(
                '- Base64 preview: ${base64Data.substring(0, math.min(50, base64Data.length))}...',
              );
            } else {
              print('ERROR: Could not read file bytes!');
            }

            requestBody['file'] = {
              'name': file.name,
              'size': file.size,
              'data': base64Data,
              'path': file.path,
              'type': 'pdf',
              'mimeType': 'application/pdf',
            };
          } else {
            print('No file provided for TSEL Learning Based');
          }
          break;

        case 'TSEL-PDF-Agent':
          // Send both PDF and prompt
          requestBody['prompt'] = prompt ?? '';
          if (file != null) {
            print('Processing file for TSEL-PDF Agent:');
            print('- File name: ${file.name}');
            print('- File size: ${file.size}');
            print('- File path: ${file.path}');

            // Try to get file bytes with fallback
            List<int>? fileBytes = await _getFileBytes(file);
            print('- File bytes available: ${fileBytes != null}');
            print('- File bytes length: ${fileBytes?.length ?? 0}');

            String? base64Data;
            if (fileBytes != null) {
              base64Data = base64Encode(fileBytes);
              print('- Base64 encoded length: ${base64Data.length}');
              print(
                '- Base64 preview: ${base64Data.substring(0, math.min(50, base64Data.length))}...',
              );
            } else {
              print('ERROR: Could not read file bytes!');
            }

            requestBody['file'] = {
              'name': file.name,
              'size': file.size,
              'data': base64Data,
              'path': file.path,
              'type': 'pdf',
              'mimeType': 'application/pdf',
            };
          } else {
            print('No file provided for TSEL-PDF Agent');
          }
          break;

        case 'TSEL-Image-Generator':
          // Send prompt only
          requestBody['prompt'] = prompt ?? '';
          break;

        case 'TSEL-Company-Agent':
          // Send prompt only
          requestBody['prompt'] = prompt ?? '';
          break;

        default:
          // Default behavior - send prompt
          requestBody['prompt'] = prompt ?? '';
          break;
      }

      print('Request body for model $model: ${json.encode(requestBody)}');

      // Also log request body structure for debugging
      print('Request body structure:');
      requestBody.forEach((key, value) {
        if (key == 'file' && value is Map) {
          print('- $key: {');
          value.forEach((fileKey, fileValue) {
            if (fileKey == 'data' &&
                fileValue is String &&
                fileValue.length > 100) {
              print('    $fileKey: [base64 data, length: ${fileValue.length}]');
            } else {
              print('    $fileKey: $fileValue');
            }
          });
          print('  }');
        } else {
          print('- $key: $value');
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Check Content-Type header to determine if response is binary
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.startsWith('image/')) {
          // Binary image response - create a special response object
          final imageBase64 = base64Encode(response.bodyBytes);
          final n8nResponse = N8NModels(
            succes: true,
            chatInput: model,
            response: imageBase64, // Store as base64 string
          );
          print(
            'Binary image response received, size: ${response.bodyBytes.length} bytes',
          );
          return n8nResponse;
        } else {
          // JSON response - parse normally
          try {
            final n8nResponse = N8NModels.fromJson(
              json.decode(response.body) as Map<String, dynamic>,
            );
            print(
              'Response from N8N for model $model: ${n8nResponse.response}',
            );
            return n8nResponse;
          } catch (e) {
            print('Error parsing JSON response: $e');
            // Fallback: treat as plain text response
            final n8nResponse = N8NModels(
              succes: true,
              chatInput: model,
              response: response.body,
            );
            return n8nResponse;
          }
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error occurred while sending request for model $model: $e');
      return null;
    }
  }

  // Alternative method to send file as multipart form data (like Postman)
  Future<N8NModels?> postPromptWithMultipart({
    required String model,
    String? prompt,
    PlatformFile? file,
  }) async {
    final url = Uri.parse(n8nUrl);
    final token = await _getToken();
    if (token == null) {
      return null; // Token tidak ditemukan
    }

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['model'] = model;
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      if (prompt != null && prompt.isNotEmpty) {
        request.fields['prompt'] = prompt;
      }

      // Add file if exists
      if (file != null) {
        print('Adding file to multipart request: ${file.name}');

        if (file.bytes != null) {
          // Use bytes directly
          var multipartFile = http.MultipartFile.fromBytes(
            'file', // field name
            file.bytes!,
            filename: file.name,
            // contentType: MediaType('application', 'pdf'), // If you have mime package
          );
          request.files.add(multipartFile);
        } else if (file.path != null) {
          // Use file path
          var multipartFile = await http.MultipartFile.fromPath(
            'file', // field name
            file.path!,
            filename: file.name,
          );
          request.files.add(multipartFile);
        }
      }

      print('Sending multipart request...');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Check Content-Type header to determine if response is binary
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.startsWith('image/')) {
          // Binary image response - create a special response object
          final imageBase64 = base64Encode(response.bodyBytes);
          final n8nResponse = N8NModels(
            succes: true,
            chatInput: model,
            response: imageBase64, // Store as base64 string
          );
          print(
            'Binary image response received, size: ${response.bodyBytes.length} bytes',
          );
          return n8nResponse;
        } else {
          // JSON response - parse normally
          try {
            final n8nResponse = N8NModels.fromJson(
              json.decode(response.body) as Map<String, dynamic>,
            );
            print('Response from N8N multipart: ${n8nResponse.response}');
            return n8nResponse;
          } catch (e) {
            print('Error parsing JSON response: $e');
            // Fallback: treat as plain text response
            final n8nResponse = N8NModels(
              succes: true,
              chatInput: model,
              response: response.body,
            );
            return n8nResponse;
          }
        }
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error occurred while sending multipart request: $e');
      return null;
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
