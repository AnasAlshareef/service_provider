import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServiceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ServiceModel> _services = [];
  List<ServiceModel> _myServices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ServiceModel> get services => _services;
  List<ServiceModel> get myServices => _myServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all active services
  Future<void> loadServices() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _services = snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load services: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load services for a specific provider
  Future<void> loadMyServices(String providerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      QuerySnapshot snapshot = await _firestore
          .collection('services')
          .where('providerId', isEqualTo: providerId)
          .orderBy('createdAt', descending: true)
          .get();

      _myServices = snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load your services: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new service
  Future<bool> addService(ServiceModel service) async {
    try {
      _errorMessage = null;
      
      await _firestore
          .collection('services')
          .doc(service.id)
          .set(service.toMap());

      _myServices.insert(0, service);
      if (service.isActive) {
        _services.insert(0, service);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add service: $e';
      notifyListeners();
      return false;
    }
  }

  // Update an existing service
  Future<bool> updateService(ServiceModel service) async {
    try {
      _errorMessage = null;
      
      await _firestore
          .collection('services')
          .doc(service.id)
          .update(service.toMap());

      // Update in local lists
      int myIndex = _myServices.indexWhere((s) => s.id == service.id);
      if (myIndex != -1) {
        _myServices[myIndex] = service;
      }

      int allIndex = _services.indexWhere((s) => s.id == service.id);
      if (allIndex != -1) {
        if (service.isActive) {
          _services[allIndex] = service;
        } else {
          _services.removeAt(allIndex);
        }
      } else if (service.isActive) {
        _services.insert(0, service);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update service: $e';
      notifyListeners();
      return false;
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    try {
      _errorMessage = null;
      
      await _firestore
          .collection('services')
          .doc(serviceId)
          .delete();

      _myServices.removeWhere((s) => s.id == serviceId);
      _services.removeWhere((s) => s.id == serviceId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete service: $e';
      notifyListeners();
      return false;
    }
  }

  // Get services by category
  List<ServiceModel> getServicesByCategory(String category) {
    return _services.where((service) => service.category == category).toList();
  }

  // Search services
  List<ServiceModel> searchServices(String query) {
    if (query.isEmpty) return _services;
    
    return _services.where((service) =>
        service.title.toLowerCase().contains(query.toLowerCase()) ||
        service.description.toLowerCase().contains(query.toLowerCase()) ||
        service.category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Get unique categories
  List<String> getCategories() {
    Set<String> categories = _services.map((service) => service.category).toSet();
    return categories.toList()..sort();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

