import '../utils/constants.dart';

class Appointment {
  final int? id;
  final int clientId;
  final String clientName;
  final DateTime dateTime;
  final String service;
  final double price;
  final String? address;
  final AppointmentStatus status;
  final String? notes;
  final List<String>? photos;
  
  Appointment({
    this.id,
    required this.clientId,
    required this.clientName,
    required this.dateTime,
    required this.service,
    required this.price,
    this.address,
    this.status = AppointmentStatus.scheduled,
    this.notes,
    this.photos,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'dateTime': dateTime.toIso8601String(),
      'service': service,
      'price': price,
      'address': address,
      'status': status.index,
      'notes': notes,
      'photos': photos?.join('|'),
    };
  }
  
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      clientName: map['clientName'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      service: map['service'] as String,
      price: (map['price'] as num).toDouble(),
      address: map['address'] as String?,
      status: AppointmentStatus.values[map['status'] as int],
      notes: map['notes'] as String?,
      photos: map['photos'] != null 
          ? (map['photos'] as String).split('|') 
          : null,
    );
  }
  
  Appointment copyWith({
    int? id,
    int? clientId,
    String? clientName,
    DateTime? dateTime,
    String? service,
    double? price,
    String? address,
    AppointmentStatus? status,
    String? notes,
    List<String>? photos,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      dateTime: dateTime ?? this.dateTime,
      service: service ?? this.service,
      price: price ?? this.price,
      address: address ?? this.address,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
    );
  }
}