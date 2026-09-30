import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Longest side of an uploaded photo.
const maxPhotoSide = 1600;

/// Any photo the device can show (JPEG, PNG, HEIC, WebP...) as a JPEG of
/// at most [maxPhotoSide] px, or null when it can't be read.
///
/// Decoding goes through the platform (so iPhone/Galaxy HEIC photos work
/// and the camera's rotation is applied); re-encoding drops the EXIF
/// metadata, including the GPS position photos often carry.
Future<Uint8List?> prepareUploadPhoto(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width, h = image.height;
    image.dispose();
    codec.dispose();
    if (rgba == null) return null;
    return await compute(_encodeJpeg, (rgba.buffer.asUint8List(), w, h));
  } catch (e) {
    debugPrint('photo prep failed: $e');
    return null;
  }
}

Uint8List _encodeJpeg((Uint8List, int, int) a) {
  final (rgba, w, h) = a;
  var im = img.Image.fromBytes(
    width: w,
    height: h,
    bytes: rgba.buffer,
    numChannels: 4,
  );
  // Transparent parts (PNG screenshots) on white rather than black.
  final flat = img.Image(width: w, height: h)
    ..clear(img.ColorRgb8(255, 255, 255));
  im = img.compositeImage(flat, im);
  if (w > maxPhotoSide || h > maxPhotoSide) {
    im = w >= h
        ? img.copyResize(im, width: maxPhotoSide)
        : img.copyResize(im, height: maxPhotoSide);
  }
  return img.encodeJpg(im, quality: 82);
}

/// Longest side of a profile photo.
const avatarSide = 400;

/// A profile photo: the middle square of the picture as a
/// [avatarSide] px JPEG, or null when it can't be read.
Future<Uint8List?> prepareAvatar(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width, h = image.height;
    image.dispose();
    codec.dispose();
    if (rgba == null) return null;
    return await compute(_encodeAvatar, (rgba.buffer.asUint8List(), w, h));
  } catch (e) {
    debugPrint('avatar prep failed: $e');
    return null;
  }
}

Uint8List _encodeAvatar((Uint8List, int, int) a) {
  final (rgba, w, h) = a;
  final im = img.Image.fromBytes(
    width: w,
    height: h,
    bytes: rgba.buffer,
    numChannels: 4,
  );
  final flat = img.Image(width: w, height: h)
    ..clear(img.ColorRgb8(255, 255, 255));
  final side = w < h ? w : h;
  final square = img.copyCrop(
    img.compositeImage(flat, im),
    x: (w - side) ~/ 2,
    y: (h - side) ~/ 2,
    width: side,
    height: side,
  );
  final out = side > avatarSide
      ? img.copyResize(square, width: avatarSide, height: avatarSide)
      : square;
  return img.encodeJpg(out, quality: 85);
}
