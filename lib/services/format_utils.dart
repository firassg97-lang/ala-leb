import 'package:timeago/timeago.dart' as timeago;

class FormatUtils {
  static String formatPrice(double price, {bool isRental = false}) {
    final formatted =
        price == price.truncateToDouble() ? price.toInt().toString() : price.toStringAsFixed(2);
    if (isRental) return '$formatted TND/jour';
    return '$formatted TND';
  }

  static String formatTimeAgo(DateTime date, String locale) {
    return timeago.format(date, locale: locale);
  }

  static String conditionLabel(String condition, String locale) {
    final map = {
      'ar': {'new': 'جديد', 'good_used': 'حالة جيدة', 'used': 'مستعمل'},
      'fr': {'new': 'Nouveau', 'good_used': 'Bon état', 'used': 'Utilisé'},
      'en': {'new': 'New', 'good_used': 'Good', 'used': 'Used'},
      'tn': {'new': 'جديد', 'good_used': 'حالة بهية', 'used': 'مستعمل'},
    };
    return map[locale]?[condition] ?? condition;
  }
}
