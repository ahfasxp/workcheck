import 'package:flutter_test/flutter_test.dart';
import 'package:workcheck/app/app.locator.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ReplicateServiceTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
