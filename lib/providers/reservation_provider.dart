import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation_model.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ReservationModel> _customerReservations = [];
  List<ReservationModel> _providerReservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReservationModel> get customerReservations => _customerReservations;
  List<ReservationModel> get providerReservations => _providerReservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load reservations for a customer
  Future<void> loadCustomerReservations(String customerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      _customerReservations = snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load reservations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load reservations for a provider
  Future<void> loadProviderReservations(String providerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('reservations')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      _providerReservations = snapshot.docs
          .map((doc) => ReservationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load reservations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new reservation
  Future<bool> createReservation(ReservationModel reservation) async {
    try {
      _errorMessage = null;
      
      await _firestore
          .collection('reservations')
          .doc(reservation.id)
          .set(reservation.toMap());

      _customerReservations.insert(0, reservation);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create reservation: $e';
      notifyListeners();
      return false;
    }
  }

  // Confirm reservation by customer
  Future<bool> confirmReservation(String reservationId) async {
    try {
      _errorMessage = null;
      
      ReservationModel? reservation = _customerReservations
          .firstWhere((r) => r.id == reservationId);

      if (!reservation.canBeConfirmedByCustomer) {
        _errorMessage = 'Reservation cannot be confirmed in current status';
        notifyListeners();
        return false;
      }

      ReservationModel updatedReservation = reservation.copyWith(
        status: ReservationStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updatedReservation.toMap());

      _updateReservationInLists(updatedReservation);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to confirm reservation: $e';
      notifyListeners();
      return false;
    }
  }

  // Cancel reservation by customer
  Future<bool> cancelReservation(String reservationId) async {
    try {
      _errorMessage = null;
      
      ReservationModel? reservation = _customerReservations
          .firstWhere((r) => r.id == reservationId);

      if (!reservation.canBeCancelledByCustomer) {
        _errorMessage = 'Reservation cannot be cancelled in current status';
        notifyListeners();
        return false;
      }

      ReservationModel updatedReservation = reservation.copyWith(
        status: ReservationStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updatedReservation.toMap());

      _updateReservationInLists(updatedReservation);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel reservation: $e';
      notifyListeners();
      return false;
    }
  }

  // Accept reservation by provider
  Future<bool> acceptReservation(String reservationId, String? response) async {
    try {
      _errorMessage = null;
      
      ReservationModel? reservation = _providerReservations
          .firstWhere((r) => r.id == reservationId);

      if (!reservation.canBeRespondedByProvider) {
        _errorMessage = 'Reservation cannot be responded to in current status';
        notifyListeners();
        return false;
      }

      ReservationModel updatedReservation = reservation.copyWith(
        status: ReservationStatus.accepted,
        providerResponse: response,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updatedReservation.toMap());

      _updateReservationInLists(updatedReservation);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to accept reservation: $e';
      notifyListeners();
      return false;
    }
  }

  // Decline reservation by provider
  Future<bool> declineReservation(String reservationId, String? response) async {
    try {
      _errorMessage = null;
      
      ReservationModel? reservation = _providerReservations
          .firstWhere((r) => r.id == reservationId);

      if (!reservation.canBeRespondedByProvider) {
        _errorMessage = 'Reservation cannot be responded to in current status';
        notifyListeners();
        return false;
      }

      ReservationModel updatedReservation = reservation.copyWith(
        status: ReservationStatus.declined,
        providerResponse: response,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updatedReservation.toMap());

      _updateReservationInLists(updatedReservation);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to decline reservation: $e';
      notifyListeners();
      return false;
    }
  }

  // Mark reservation as completed
  Future<bool> completeReservation(String reservationId) async {
    try {
      _errorMessage = null;
      
      ReservationModel? reservation = _providerReservations
          .firstWhere((r) => r.id == reservationId);

      ReservationModel updatedReservation = reservation.copyWith(
        status: ReservationStatus.completed,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updatedReservation.toMap());

      _updateReservationInLists(updatedReservation);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete reservation: $e';
      notifyListeners();
      return false;
    }
  }

  void _updateReservationInLists(ReservationModel updatedReservation) {
    // Update in customer reservations
    int customerIndex = _customerReservations
        .indexWhere((r) => r.id == updatedReservation.id);
    if (customerIndex != -1) {
      _customerReservations[customerIndex] = updatedReservation;
    }

    // Update in provider reservations
    int providerIndex = _providerReservations
        .indexWhere((r) => r.id == updatedReservation.id);
    if (providerIndex != -1) {
      _providerReservations[providerIndex] = updatedReservation;
    }

    notifyListeners();
  }

  // Get reservations by status
  List<ReservationModel> getReservationsByStatus(
      List<ReservationModel> reservations, 
      ReservationStatus status) {
    return reservations.where((r) => r.status == status).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

