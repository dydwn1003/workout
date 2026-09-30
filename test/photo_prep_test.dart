import 'dart:typed_data';

import 'package:adapt_coach/data/community.dart';
import 'package:adapt_coach/data/photo_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('photos become a JPEG without metadata, at most 1600 px', () async {
    final src = img.Image(width: 2400, height: 1200)
      ..clear(img.ColorRgb8(200, 100, 50));
    src.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(37, 1);
    final png = img.encodePng(src);
    final out = await prepareUploadPhoto(Uint8List.fromList(png));
    expect(out, isNotNull);
    expect(imageMimeType(out!), 'image/jpeg');
    final back = img.decodeJpg(out)!;
    expect(back.width, 1600);
    expect(back.height, 800);
    expect(back.exif.gpsIfd.isEmpty, isTrue);
  });

  test('unreadable bytes give null', () async {
    expect(await prepareUploadPhoto(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });

  test('profile photos: the middle square, 400 px', () async {
    final src = img.Image(width: 1200, height: 800)
      ..clear(img.ColorRgb8(10, 120, 200));
    final out = await prepareAvatar(Uint8List.fromList(img.encodePng(src)));
    final back = img.decodeJpg(out!)!;
    expect((back.width, back.height), (400, 400));
  });
}
