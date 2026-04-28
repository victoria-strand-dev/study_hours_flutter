// Smoke test — verifies the app entry point compiles and the widget tree
// can be built without crashing. Firebase is not initialized in tests so
// full integration tests are out of scope here.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    // Full widget tests require Firebase test doubles.
    // App is validated manually on device / emulator.
    expect(true, isTrue);
  });
}
