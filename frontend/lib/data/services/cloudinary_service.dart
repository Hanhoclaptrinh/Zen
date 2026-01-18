import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';

class CloudinaryService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  // nén ảnh để tối ưu dung lượng và tốc độ upload
  Future<File?> _compressImage(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tempDir.path,
        '${p.basenameWithoutExtension(file.path)}_compressed.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        format: CompressFormat.jpeg,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      _logger.e('Error compressing image: $e');
      return file;
    }
  }

  // upload file lên cloudinary
  Future<String?> uploadFile(
    File file, {
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      // nén ảnh trước khi gửi
      final compressedFile = await _compressImage(file);
      final finalFile = compressedFile ?? file;

      final cloudName = dotenv.env['CLOUDNAME'];
      final uploadPreset = dotenv.env['UPLOADPRESET'];

      if (cloudName == null || uploadPreset == null) {
        throw Exception(
          'Cloudinary config (CLOUDNAME/UPLOADPRESET) not found in .env',
        );
      }

      final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          finalFile.path,
          filename: p.basename(finalFile.path),
        ),
        'upload_preset': uploadPreset,
        'folder': 'zen_app',
      });

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('Error uploading to Cloudinary: $e');
      rethrow;
    }
  }
}
