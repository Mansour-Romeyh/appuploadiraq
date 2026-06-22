import 'package:flutter_test/flutter_test.dart';
import 'package:dill_adala/screens/contact_screen.dart';

void main() {
  test('officeWazeUri points Waze at the office coordinates', () {
    final uri = officeWazeUri();
    expect(uri.scheme, 'waze');
    expect(uri.queryParameters['ll'], '$officeLat,$officeLng');
    expect(uri.queryParameters['navigate'], 'yes');
  });

  test('office coordinates match the resolved company pin', () {
    // Resolved from https://maps.app.goo.gl/YgWfQVyBsw9bmLyD7
    expect(officeLat, 33.2954188);
    expect(officeLng, 44.3553345);
    expect(officeMapsUrl, 'https://maps.app.goo.gl/YgWfQVyBsw9bmLyD7');
  });
}
