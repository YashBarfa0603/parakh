import 'package:intl/intl.dart';

/// Centralized date & time utilities for PARAKH.
/// Ensures UTC timestamps received from backend are correctly converted to local device time.
class AppDateUtils {
  AppDateUtils._();

  /// Parse a date string from the backend into a local [DateTime].
  /// If the timestamp is naive (lacks 'Z' or timezone offset), it is assumed to be in UTC
  /// because the backend database persists timestamps in UTC.
  static DateTime? parseUtc(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    try {
      String normalized = trimmed;
      // If missing timezone indicator, treat as UTC
      if (!normalized.endsWith('Z') &&
          !normalized.contains('+') &&
          !RegExp(r'-\d{2}:\d{2}$').hasMatch(normalized)) {
        normalized = '${normalized}Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(trimmed).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  /// Format as date + time, e.g. "22 Sep 2026, 05:27 PM"
  static String formatDateTime(String? raw, {String fallback = '—'}) {
    final dt = parseUtc(raw);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  /// Format as short date only, e.g. "22 Sep 2026"
  static String formatShortDate(String? raw, {String fallback = '—'}) {
    final dt = parseUtc(raw);
    if (dt == null) return fallback;
    return DateFormat('dd MMM yyyy').format(dt);
  }

  /// Format as 12-hour time only, e.g. "05:27 PM"
  static String formatTimeOnly(String? raw, {String fallback = '—'}) {
    final dt = parseUtc(raw);
    if (dt == null) return fallback;
    return DateFormat('hh:mm a').format(dt);
  }

  /// Format for home screen "Last Inspection" stat card:
  /// - If today: "05:27 PM"
  /// - If yesterday: "Yesterday"
  /// - If older: "dd MMM" (e.g. "18 Sep")
  /// - If null: fallback
  static String formatLastInspectionTime(String? raw, {String fallback = '—'}) {
    final dt = parseUtc(raw);
    if (dt == null) return fallback;

    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return DateFormat('hh:mm a').format(dt);
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isYesterday) {
      return 'Yesterday';
    }

    return DateFormat('dd MMM').format(dt);
  }

  /// Format for recent inspection list rows:
  /// - If today: "Today, 05:27 PM"
  /// - If yesterday: "Yesterday, 05:27 PM"
  /// - If other: "dd/MM/yyyy, 05:27 PM"
  static String formatRecentRowDate(String? raw, {String fallback = 'Recent'}) {
    final dt = parseUtc(raw);
    if (dt == null) return fallback;

    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final timeStr = DateFormat('hh:mm a').format(dt);

    if (isToday) {
      return 'Today, $timeStr';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
    if (isYesterday) {
      return 'Yesterday, $timeStr';
    }

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}, $timeStr';
  }
}
