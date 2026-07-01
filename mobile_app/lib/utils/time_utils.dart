import 'package:intl/intl.dart';

class TimeUtils {
  static String formatLastSeen(String? lastSeenStr) {
    if (lastSeenStr == null || lastSeenStr.isEmpty) return '';
    
    try {
      DateTime lastSeen = DateTime.parse(lastSeenStr).toLocal();
      DateTime now = DateTime.now();
      Duration diff = now.difference(lastSeen);
      
      if (diff.inMinutes < 1) return 'last seen just now';
      if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes} min ago';
      if (diff.inHours < 24) {
        if (lastSeen.day == now.day) {
          return 'last seen today at ${DateFormat('h:mm a').format(lastSeen)}';
        }
        return 'last seen yesterday at ${DateFormat('h:mm a').format(lastSeen)}';
      }
      
      DateTime yesterday = now.subtract(const Duration(days: 1));
      if (lastSeen.day == yesterday.day && lastSeen.month == yesterday.month && lastSeen.year == yesterday.year) {
        return 'last seen yesterday at ${DateFormat('h:mm a').format(lastSeen)}';
      }
      
      if (lastSeen.year == now.year) {
        return 'last seen ${DateFormat('MMM d').format(lastSeen)} at ${DateFormat('h:mm a').format(lastSeen)}';
      }
      
      return 'last seen ${DateFormat('MMM d, yyyy').format(lastSeen)}';
    } catch (_) {
      return '';
    }
  }
}
