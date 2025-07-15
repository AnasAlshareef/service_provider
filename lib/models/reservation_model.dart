enum ReservationStatus {
  pending, // Customer created reservation, waiting for confirmation
  confirmed, // Customer confirmed the reservation
  accepted, // Provider accepted the reservation
  declined, // Provider declined the reservation
  cancelled, // Customer cancelled the reservation
  completed, // Service completed
}

class ReservationModel {
  final String id;
  final String customerId;
  final String customerName;
  final String providerId;
  final String providerName;
  final String serviceId;
  final String serviceTitle;
  final double servicePrice;
  final DateTime requestedDate;
  final String requestedTime;
  final ReservationStatus status;
  final String? notes;
  final String? providerResponse;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReservationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.providerId,
    required this.providerName,
    required this.serviceId,
    required this.serviceTitle,
    required this.servicePrice,
    required this.requestedDate,
    required this.requestedTime,
    required this.status,
    this.notes,
    this.providerResponse,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'providerId': providerId,
      'providerName': providerName,
      'serviceId': serviceId,
      'serviceTitle': serviceTitle,
      'servicePrice': servicePrice,
      'requestedDate': requestedDate.toIso8601String(),
      'requestedTime': requestedTime,
      'status': status.name,
      'notes': notes,
      'providerResponse': providerResponse,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceTitle: map['serviceTitle'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0.0).toDouble(),
      requestedDate: DateTime.parse(map['requestedDate'] ?? DateTime.now().toIso8601String()),
      requestedTime: map['requestedTime'] ?? '',
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      notes: map['notes'],
      providerResponse: map['providerResponse'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  ReservationModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? providerId,
    String? providerName,
    String? serviceId,
    String? serviceTitle,
    double? servicePrice,
    DateTime? requestedDate,
    String? requestedTime,
    ReservationStatus? status,
    String? notes,
    String? providerResponse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      servicePrice: servicePrice ?? this.servicePrice,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      providerResponse: providerResponse ?? this.providerResponse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending Confirmation';
      case ReservationStatus.confirmed:
        return 'Confirmed - Awaiting Provider';
      case ReservationStatus.accepted:
        return 'Accepted';
      case ReservationStatus.declined:
        return 'Declined';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.completed:
        return 'Completed';
    }
  }

  bool get canBeConfirmedByCustomer => status == ReservationStatus.pending;
  bool get canBeCancelledByCustomer => 
      status == ReservationStatus.pending || status == ReservationStatus.confirmed;
  bool get canBeRespondedByProvider => status == ReservationStatus.confirmed;
}

