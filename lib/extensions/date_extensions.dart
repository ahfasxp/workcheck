import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String get toddMMyyyyHHmmss => DateFormat('dd-MM-yyyy HH:mm:ss').format(this);
}
