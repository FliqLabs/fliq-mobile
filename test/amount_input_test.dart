import 'package:flutter_test/flutter_test.dart';

import 'package:fliq/utils/amount_input.dart';

String typeKeys(List<String> keys) =>
    keys.fold('0', (amount, key) => applyAmountKey(amount, key));

void main() {
  test('first digit replaces the leading zero', () {
    expect(typeKeys(['5']), '5');
    expect(typeKeys(['0', '0', '7']), '7');
  });

  test('allows one decimal point with at most two decimals', () {
    expect(typeKeys(['1', '.', '.', '5']), '1.5');
    expect(typeKeys(['1', '.', '2', '3', '4']), '1.23');
    expect(typeKeys(['.', '0', '5']), '0.05');
  });

  test('delete removes the last character and never leaves it empty', () {
    expect(typeKeys(['1', '2', 'delete']), '1');
    expect(typeKeys(['1', 'delete', 'delete']), '0');
    expect(typeKeys(['.', 'delete']), '0');
  });

  test('caps the amount length', () {
    expect(typeKeys(List.filled(15, '9')), '9999999999');
    expect(typeKeys([...List.filled(10, '9'), '.']), '9999999999');
  });
}
