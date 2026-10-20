import 'package:lschmidt_portfolio/domain/entities/currently_item.dart';

List<CurrentlyItem> filterStaleCurrently(
  List<CurrentlyItem> items,
  DateTime now, {
  Duration maxAge = const Duration(days: 60),
}) => items.where((item) {
  final date = item.date;
  return date == null || now.difference(date) <= maxAge;
}).toList();
