// App Constants
class AppConstants {
  // App Information
  static const String appName = 'NSS App';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Not Me But You';
  
  // Firebase Collection Names (to be used later with backend)
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String attendanceCollection = 'attendance';
  static const String notificationsCollection = 'notifications';
  
  // Role Constants
  static const String roleVolunteer = 'volunteer';
  static const String roleAdmin = 'admin';
  
  // Event Status
  static const String eventStatusUpcoming = 'upcoming';
  static const String eventStatusOngoing = 'ongoing';
  static const String eventStatusCompleted = 'completed';
  
  // Participation Status
  static const String participationStatusPending = 'pending';
  static const String participationStatusApproved = 'approved';
  static const String participationStatusRejected = 'rejected';
  
  // Attendance Status
  static const String attendanceStatusPresent = 'present';
  static const String attendanceStatusAbsent = 'absent';
  
  // Error Messages
  static const String errorSomethingWentWrong = 'Something went wrong. Please try again.';
  static const String errorNoInternet = 'No internet connection. Please check your connection and try again.';
  static const String errorInvalidCredentials = 'Invalid credentials. Please check your email and password.';
  
  // Success Messages
  static const String successSignUp = 'Sign up successful. Please wait for admin approval.';
  static const String successEventCreated = 'Event created successfully.';
  static const String successEventUpdated = 'Event updated successfully.';
  static const String successEventDeleted = 'Event deleted successfully.';
  static const String successVolunteerApproved = 'Volunteer approved successfully.';
  static const String successVolunteerRejected = 'Volunteer rejected successfully.';
  static const String successParticipationRequested = 'Participation request sent successfully.';
  static const String successParticipationApproved = 'Participation approved successfully.';
  static const String successParticipationRejected = 'Participation rejected successfully.';
  static const String successAttendanceMarked = 'Attendance marked successfully.';
  static const String successProfileUpdated = 'Profile updated successfully.';
  static const String successAdminAdded = 'Admin added successfully.';
  static const String successAdminRemoved = 'Admin removed successfully.';
}