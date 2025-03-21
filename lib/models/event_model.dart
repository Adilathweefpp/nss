import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final int maxParticipants;
  final List<String> registeredParticipants;
  final String createdBy;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.maxParticipants,
    this.registeredParticipants = const [],
    required this.createdBy,
    required this.createdAt,
  });

  // Check if event is upcoming
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  // Check if event is ongoing
  bool get isOngoing =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  // Check if event is past
  bool get isPast => DateTime.now().isAfter(endDate);

  // Get remaining slots
  int get remainingSlots => maxParticipants - registeredParticipants.length;
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'maxParticipants': maxParticipants,
      'registeredParticipants': registeredParticipants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  // Create EventModel from DocumentSnapshot
  factory EventModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      registeredParticipants: List<String>.from(data['registeredParticipants'] ?? []),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Mock data for UI development and testing
  static List<EventModel> getMockEvents() {
    final now = DateTime.now();
    
    return [
      EventModel(
        id: '1',
        title: 'Tree Plantation Drive',
        description: 'Join us for a tree plantation drive at the college campus. Bring your own gardening tools if possible.',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 5, hours: 4)),
        location: 'College Campus',
        maxParticipants: 50,
        registeredParticipants: ['1', '2', '3'],
        createdBy: '5',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      EventModel(
        id: '2',
        title: 'Blood Donation Camp',
        description: 'Annual blood donation camp in collaboration with Red Cross. Please come with a valid ID card.',
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 10, hours: 6)),
        location: 'College Auditorium',
        maxParticipants: 100,
        registeredParticipants: ['1', '4'],
        createdBy: '6',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      EventModel(
        id: '3',
        title: 'Clean Campus Initiative',
        description: 'Help us clean the campus and surrounding areas. Cleaning supplies will be provided.',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.subtract(const Duration(days: 5, hours: 3)),
        location: 'College Grounds',
        maxParticipants: 30,
        registeredParticipants: ['1', '2'],
        createdBy: '5',
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      EventModel(
        id: '4',
        title: 'Digital Literacy Workshop',
        description: 'Teaching basic computer skills to elderly people in the nearby community.',
        startDate: now.add(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1, hours: 3)),
        location: 'Computer Lab',
        maxParticipants: 20,
        registeredParticipants: [],
        createdBy: '6',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      EventModel(
        id: '5',
        title: 'Health Awareness Camp',
        description: 'Organizing a health awareness camp for villagers from nearby areas.',
        startDate: now.add(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 15, hours: 5)),
        location: 'Village Community Center',
        maxParticipants: 40,
        registeredParticipants: ['3'],
        createdBy: '5',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }
}





// class EventModel {
//   final String id;
//   final String title;
//   final String description;
//   final DateTime startDate;
//   final DateTime endDate;
//   final String location;
//   final int maxParticipants;
//   final List<String> registeredParticipants;
//   final List<String> approvedParticipants;
//   final String createdBy;
//   final DateTime createdAt;

//   EventModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.startDate,
//     required this.endDate,
//     required this.location,
//     required this.maxParticipants,
//     this.registeredParticipants = const [],
//     this.approvedParticipants = const [],
//     required this.createdBy,
//     required this.createdAt,
//   });

//   // Check if event is upcoming
//   bool get isUpcoming => DateTime.now().isBefore(startDate);

//   // Check if event is ongoing
//   bool get isOngoing =>
//       DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

//   // Check if event is past
//   bool get isPast => DateTime.now().isAfter(endDate);

//   // Get remaining slots
//   int get remainingSlots => maxParticipants - approvedParticipants.length;

//   // Mock data for UI development
//   static List<EventModel> getMockEvents() {
//     final now = DateTime.now();
    
//     return [
//       EventModel(
//         id: '1',
//         title: 'Tree Plantation Drive',
//         description: 'Join us for a tree plantation drive at the college campus. Bring your own gardening tools if possible.',
//         startDate: now.add(const Duration(days: 5)),
//         endDate: now.add(const Duration(days: 5, hours: 4)),
//         location: 'College Campus',
//         maxParticipants: 50,
//         registeredParticipants: ['1', '2', '3'],
//         approvedParticipants: ['1', '2'],
//         createdBy: '5',
//         createdAt: now.subtract(const Duration(days: 15)),
//       ),
//       EventModel(
//         id: '2',
//         title: 'Blood Donation Camp',
//         description: 'Annual blood donation camp in collaboration with Red Cross. Please come with a valid ID card.',
//         startDate: now.add(const Duration(days: 10)),
//         endDate: now.add(const Duration(days: 10, hours: 6)),
//         location: 'College Auditorium',
//         maxParticipants: 100,
//         registeredParticipants: ['1', '4'],
//         approvedParticipants: ['1'],
//         createdBy: '6',
//         createdAt: now.subtract(const Duration(days: 20)),
//       ),
//       EventModel(
//         id: '3',
//         title: 'Clean Campus Initiative',
//         description: 'Help us clean the campus and surrounding areas. Cleaning supplies will be provided.',
//         startDate: now.subtract(const Duration(days: 5)),
//         endDate: now.subtract(const Duration(days: 5, hours: 3)),
//         location: 'College Grounds',
//         maxParticipants: 30,
//         registeredParticipants: ['1', '2'],
//         approvedParticipants: ['1', '2'],
//         createdBy: '5',
//         createdAt: now.subtract(const Duration(days: 25)),
//       ),
//       EventModel(
//         id: '4',
//         title: 'Digital Literacy Workshop',
//         description: 'Teaching basic computer skills to elderly people in the nearby community.',
//         startDate: now.add(const Duration(days: 1)),
//         endDate: now.add(const Duration(days: 1, hours: 3)),
//         location: 'Computer Lab',
//         maxParticipants: 20,
//         registeredParticipants: [],
//         approvedParticipants: [],
//         createdBy: '6',
//         createdAt: now.subtract(const Duration(days: 10)),
//       ),
//       EventModel(
//         id: '5',
//         title: 'Health Awareness Camp',
//         description: 'Organizing a health awareness camp for villagers from nearby areas.',
//         startDate: now.add(const Duration(days: 15)),
//         endDate: now.add(const Duration(days: 15, hours: 5)),
//         location: 'Village Community Center',
//         maxParticipants: 40,
//         registeredParticipants: ['3'],
//         approvedParticipants: [],
//         createdBy: '5',
//         createdAt: now.subtract(const Duration(days: 8)),
//       ),
//     ];
//   }
// }