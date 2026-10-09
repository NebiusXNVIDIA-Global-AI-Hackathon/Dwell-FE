import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in <String>[
    'balcony_light.svg',
    'cabinet.svg',
    'washer.svg',
    'dryer.svg',
    'laundry_sink.svg',
    'pipe.svg',
    'storage.svg',
    'outdoor_outlet.svg',
    'appliance.svg',
    'balcony_door.svg',
    'balcony_floor.svg',
    'baseboard.svg',
    'ceiling.svg',
    'closet.svg',
    'countertop.svg',
    'door.svg',
    'drain.svg',
    'exterior_door.svg',
    'exterior_light.svg',
    'exterior_pipe.svg',
    'exterior_wall.svg',
    'fireplace.svg',
    'floor.svg',
    'foundation.svg',
    'gutter.svg',
    'kitchen_sink.svg',
    'kitchen_under_sink.svg',
    'kitchen_ventilation.svg',
    'light.svg',
    'other.svg',
    'outlet.svg',
    'planter.svg',
    'railing.svg',
    'roof.svg',
    'shelf.svg',
    'shower.svg',
    'sink.svg',
    'sofa.svg',
    'stairs.svg',
    'terrace.svg',
    'toilet.svg',
    'under_sink.svg',
    'vent.svg',
    'ventilation.svg',
    'walkway.svg',
    'wall.svg',
    'window.svg',
    'wood_floor.svg',
  ]) {
    test('$name renders visible pixels', () async {
      final info = await vg.loadPicture(
        SvgAssetLoader('assets/icons/areas/$name'),
        null,
      );
      final image = await info.picture.toImage(62, 56);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var visible = 0;
      for (var i = 3; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) > 0) visible++;
      }
      image.dispose();
      info.picture.dispose();
      expect(visible, greaterThan(100));
    });
  }
}
