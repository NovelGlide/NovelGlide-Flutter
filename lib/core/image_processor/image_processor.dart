import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageProcessor {
  Future<Uint8List> img2PngBytes(img.Image image) async {
    return compute<img.Image, Uint8List>(_img2PngIsolate, image);
  }

  static Future<Uint8List> _img2PngIsolate(img.Image image) async {
    return Uint8List.fromList(img.encodePng(image));
  }
}
