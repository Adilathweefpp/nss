import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  
  // Format date as "Jan 01, 2023"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  // Format time as "09:30 AM"
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }
  
  // Format day as "Monday"
  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }
  
  // Format date as "01/01/2023"
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }
  
  // Format date and time as "Jan 01, 2023 09:30 AM"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  // Format date range as "Jan 01 - Jan 05, 2023"
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && 
        startDate.month == endDate.month) {
      return '${DateFormat('MMM dd').format(startDate)} - ${_dateFormat.format(endDate)}';
    } else if (startDate.year == endDate.year) {
      return '${DateFormat('MMM dd').format(startDate)} - ${_dateFormat.format(endDate)}';
    } else {
      return '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
    }
  }
  
  // Format time range as "09:30 AM - 12:30 PM"
  static String formatTimeRange(DateTime startTime, DateTime endTime) {
    return '${_timeFormat.format(startTime)} - ${_timeFormat.format(endTime)}';
  }
  
  // Calculate time difference in a human-readable format
  static String getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
  
  // Calculate time until a date in a human-readable format
  static String getTimeUntil(DateTime dateTime) {
    final difference = dateTime.difference(DateTime.now());
    
    if (difference.inDays > 365) {
      return 'in ${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'}';
    } else if (difference.inDays > 30) {
      return 'in ${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'}';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return 'now';
    }
  }
}