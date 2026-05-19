import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static final _picker = ImagePicker();

  static Future<File?> pickAndCompress({
    required ImageSource source,
    int thumbnailQuality = 75,
    int fullQuality = 85,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2048,
      maxHeight: 2048,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    return _compressFull(picked.path, fullQuality);
  }

  static Future<File?> _compressFull(String path, int quality) async {
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      quality: quality,
      minWidth: 1024,
      minHeight: 1024,
      format: CompressFormat.jpeg,
    );
    if (result == null) return null;
    return File(result.path);
  }

  static Future<File?> compressThumbnail(String path) async {
    final dir = await getTemporaryDirectory();
    final target =
        '${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      target,
      quality: 70,
      minWidth: 400,
      minHeight: 400,
      format: CompressFormat.jpeg,
    );
    if (result == null) return null;
    return File(result.path);
  }
}
