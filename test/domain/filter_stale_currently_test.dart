import 'package:flutter_test/flutter_test.dart';
import 'package:lschmidt_portfolio/domain/entities/currently_item.dart';
import 'package:lschmidt_portfolio/domain/usecases/filter_stale_currently.dart';

void main() {
  final now = DateTime(2026, 10, 20);
  const undated = CurrentlyItem(label: 'STATUS', value: 'Open');

  CurrentlyItem dated(int daysAgo) => CurrentlyItem(
    label: 'NOW',
    value: 'item $daysAgo',
    date: now.subtract(Duration(days: daysAgo)),
  );

  test('keeps undated items', () {
    expect(filterStaleCurrently(const [undated], now), const [undated]);
  });

  test('drops an item dated 61 days ago', () {
    final stale = dated(61);
    expect(filterStaleCurrently([undated, stale], now), const [undated]);
  });

  test('keeps an item dated 59 days ago', () {
    final fresh = dated(59);
    expect(filterStaleCurrently([undated, fresh], now), [undated, fresh]);
  });

  test('keeps an item dated exactly at the limit', () {
    final edge = dated(60);
    expect(filterStaleCurrently([edge], now), [edge]);
  });

  test('honours a custom max age', () {
    final item = dated(10);
    expect(
      filterStaleCurrently([item], now, maxAge: const Duration(days: 5)),
      isEmpty,
    );
  });

  test('keeps dated items when the clock is behind', () {
    final item = dated(0);
    expect(
      filterStaleCurrently([item], now.subtract(const Duration(days: 3650))),
      [item],
    );
  });

  test('with the clock ten years ahead only undated items remain', () {
    final farFuture = now.add(const Duration(days: 3650));
    final items = [undated, dated(0), dated(30)];
    expect(filterStaleCurrently(items, farFuture), const [undated]);
  });

  test('keeps the order of the surviving items', () {
    final a = dated(1);
    final b = dated(2);
    expect(filterStaleCurrently([a, undated, b], now), [a, undated, b]);
  });
}
