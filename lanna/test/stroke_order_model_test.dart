import 'package:flutter_test/flutter_test.dart';
import 'package:lanna/page/lean/train/stroke_order_model.dart';

void main() {
  test('unknown characters never receive invented stroke paths', () {
    expect(getCharacterStrokeOrder('🙂'), isNull);
    expect(getCharacterStrokeOrder(''), isNull);
  });
}
