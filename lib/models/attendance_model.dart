import 'package:nss_app/models/event_model.dart';

class AttendanceModel {
  final String id;
  final String eventId;
  final String volunteerId;
  final bool isPresent;
  final String markedBy;
  final DateTime markedAt;

  AttendanceModel({
    required this.id,
    required this.eventId,
    required this.volunteerId,
    required this.isPresent,
    required this.markedBy,
    required this.markedAt,
  });

  // Mock data for UI development
  static List<AttendanceModel> getMockAttendance() {
    return [
      AttendanceModel(
        id: '1',
        eventId: '3', // Clean Campus Initiative (past event)
        volunteerId: '1', 
        isPresent: true,
        markedBy: '5', 
        markedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      AttendanceModel(
        id: '2',
        eventId: '3', // Clean Campus Initiative (past event)
        volunteerId: '2', 
        isPresent: true,
        markedBy: '5', 
        markedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      AttendanceModel(
        id: '3',
        eventId: '2', // Blood Donation Camp
        volunteerId: '1', 
        isPresent: true,
        markedBy: '6', 
        markedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AttendanceModel(
        id: '4',
        eventId: '1', // Tree Plantation Drive
        volunteerId: '1', 
        isPresent: true,
        markedBy: '5', 
        markedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AttendanceModel(
        id: '5',
        eventId: '1', // Tree Plantation Drive
        volunteerId: '2', 
        isPresent: true,
        markedBy: '5', 
        markedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // Method to get attendance for a specific volunteer
  static List<AttendanceModel> getVolunteerAttendance(String volunteerId) {
    return getMockAttendance().where((attendance) => attendance.volunteerId == volunteerId).toList();
  }

  // Method to get attendance for a specific event
  static List<AttendanceModel> getEventAttendance(String eventId) {
    return getMockAttendance().where((attendance) => attendance.eventId == eventId).toList();
  }

  // Method to calculate attendance percentage for a volunteer
  static double calculateAttendancePercentage(String volunteerId) {
    // Get all events the volunteer was registered for
    final registeredEvents = EventModel.getMockEvents()
        .where((event) => event.registeredParticipants.contains(volunteerId) && event.isPast)
        .map((event) => event.id)
        .toList();
    
    // If no registered events, return 0
    if (registeredEvents.isEmpty) return 0.0;
    
    // Get attendance records for the volunteer
    final attendanceRecords = getVolunteerAttendance(volunteerId)
        .where((record) => registeredEvents.contains(record.eventId))
        .toList();
    
    // Count events where volunteer was present
    final presentCount = attendanceRecords
        .where((record) => record.isPresent)
        .length;
    
    // Calculate percentage
    return (presentCount / registeredEvents.length) * 100;
  }
  
  // Method to check if a volunteer was present at a specific event
  static bool wasVolunteerPresent(String volunteerId, String eventId) {
    final attendances = getVolunteerAttendance(volunteerId)
        .where((attendance) => attendance.eventId == eventId)
        .toList();
    
    if (attendances.isEmpty) return false;
    return attendances.first.isPresent;
  }
  
  // Method to mark attendance for a volunteer at an event
  static void markAttendance(String volunteerId, String eventId, bool isPresent, String adminId) {
    final attendances = getMockAttendance();
    
    // Check if attendance already exists
    final existingIndex = attendances.indexWhere(
      (attendance) => attendance.volunteerId == volunteerId && attendance.eventId == eventId
    );
    
    if (existingIndex >= 0) {
      // Update existing attendance
      attendances[existingIndex] = AttendanceModel(
        id: attendances[existingIndex].id,
        eventId: eventId,
        volunteerId: volunteerId,
        isPresent: isPresent,
        markedBy: adminId,
        markedAt: DateTime.now(),
      );
    } else {
      // Create new attendance record
      attendances.add(
        AttendanceModel(
          id: (attendances.length + 1).toString(),
          eventId: eventId,
          volunteerId: volunteerId,
          isPresent: isPresent,
          markedBy: adminId,
          markedAt: DateTime.now(),
        ),
      );
    }
  }
}




// import 'package:nss_app/models/event_model.dart';

// class AttendanceModel {
//   final String id;
//   final String eventId;
//   final String volunteerId;
//   final bool isPresent;
//   final String markedBy;
//   final DateTime markedAt;

//   AttendanceModel({
//     required this.id,
//     required this.eventId,
//     required this.volunteerId,
//     required this.isPresent,
//     required this.markedBy,
//     required this.markedAt,
//   });

//   // Mock data for UI development
//   static List<AttendanceModel> getMockAttendance() {
//     return [
//       AttendanceModel(
//         id: '1',
//         eventId: '3', // Clean Campus Initiative (past event)
//         volunteerId: '1', 
//         isPresent: true,
//         markedBy: '5', 
//         markedAt: DateTime.now().subtract(const Duration(days: 5)),
//       ),
//       AttendanceModel(
//         id: '2',
//         eventId: '3', // Clean Campus Initiative (past event)
//         volunteerId: '2', 
//         isPresent: true,
//         markedBy: '5', 
//         markedAt: DateTime.now().subtract(const Duration(days: 5)),
//       ),
//       AttendanceModel(
//         id: '3',
//         eventId: '2', // Blood Donation Camp
//         volunteerId: '1', 
//         isPresent: true,
//         markedBy: '6', 
//         markedAt: DateTime.now().subtract(const Duration(days: 2)),
//       ),
//       AttendanceModel(
//         id: '4',
//         eventId: '1', // Tree Plantation Drive
//         volunteerId: '1', 
//         isPresent: true,
//         markedBy: '5', 
//         markedAt: DateTime.now().subtract(const Duration(days: 1)),
//       ),
//       AttendanceModel(
//         id: '5',
//         eventId: '1', // Tree Plantation Drive
//         volunteerId: '2', 
//         isPresent: true,
//         markedBy: '5', 
//         markedAt: DateTime.now().subtract(const Duration(days: 1)),
//       ),
//     ];
//   }

//   // Method to get attendance for a specific volunteer
//   static List<AttendanceModel> getVolunteerAttendance(String volunteerId) {
//     return getMockAttendance().where((attendance) => attendance.volunteerId == volunteerId).toList();
//   }

//   // Method to get attendance for a specific event
//   static List<AttendanceModel> getEventAttendance(String eventId) {
//     return getMockAttendance().where((attendance) => attendance.eventId == eventId).toList();
//   }

//   // Method to calculate attendance percentage for a volunteer
//   static double calculateAttendancePercentage(String volunteerId) {
//     // Get all events the volunteer was approved for
//     final approvedEvents = EventModel.getMockEvents()
//         .where((event) => event.approvedParticipants.contains(volunteerId) && event.isPast)
//         .map((event) => event.id)
//         .toList();
    
//     // If no approved events, return 0
//     if (approvedEvents.isEmpty) return 0.0;
    
//     // Get attendance records for the volunteer
//     final attendanceRecords = getVolunteerAttendance(volunteerId)
//         .where((record) => approvedEvents.contains(record.eventId))
//         .toList();
    
//     // Count events where volunteer was present
//     final presentCount = attendanceRecords
//         .where((record) => record.isPresent)
//         .length;
    
//     // Calculate percentage
//     return (presentCount / approvedEvents.length) * 100;
//   }
  
//   // Method to check if a volunteer was present at a specific event
//   static bool wasVolunteerPresent(String volunteerId, String eventId) {
//     final attendances = getVolunteerAttendance(volunteerId)
//         .where((attendance) => attendance.eventId == eventId)
//         .toList();
    
//     if (attendances.isEmpty) return false;
//     return attendances.first.isPresent;
//   }
  
//   // Method to mark attendance for a volunteer at an event
//   static void markAttendance(String volunteerId, String eventId, bool isPresent, String adminId) {
//     final attendances = getMockAttendance();
    
//     // Check if attendance already exists
//     final existingIndex = attendances.indexWhere(
//       (attendance) => attendance.volunteerId == volunteerId && attendance.eventId == eventId
//     );
    
//     if (existingIndex >= 0) {
//       // Update existing attendance
//       attendances[existingIndex] = AttendanceModel(
//         id: attendances[existingIndex].id,
//         eventId: eventId,
//         volunteerId: volunteerId,
//         isPresent: isPresent,
//         markedBy: adminId,
//         markedAt: DateTime.now(),
//       );
//     } else {
//       // Create new attendance record
//       attendances.add(
//         AttendanceModel(
//           id: (attendances.length + 1).toString(),
//           eventId: eventId,
//           volunteerId: volunteerId,
//           isPresent: isPresent,
//           markedBy: adminId,
//           markedAt: DateTime.now(),
//         ),
//       );
//     }
//   }
// }