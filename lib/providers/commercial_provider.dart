import 'package:flutter/foundation.dart';
import 'package:sntf/data/models/commercial.dart';
import 'package:sntf/data/services/supabase_service.dart';

/// Loading state for commercial operations
enum CommercialLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// CommercialProvider manages tickets, abonnements, and amendes
class CommercialProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  // State
  CommercialLoadingState _state = CommercialLoadingState.initial;
  String? _errorMessage;
  bool _isProcessing = false;
  
  // Data
  List<Ticket> _tickets = [];
  List<Abonnement> _abonnements = [];
  List<Amende> _amendes = [];
  Abonnement? _activeAbonnement;
  
  // User ID
  String? _userId;
  
  // Getters
  CommercialLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == CommercialLoadingState.loading;
  bool get isProcessing => _isProcessing;
  bool get hasError => _state == CommercialLoadingState.error;
  
  List<Ticket> get tickets => _tickets;
  List<Abonnement> get abonnements => _abonnements;
  List<Amende> get amendes => _amendes;
  Abonnement? get activeAbonnement => _activeAbonnement;
  
  // Filtered getters
  List<Ticket> get validTickets => 
      _tickets.where((t) => t.estValide).toList();
  
  List<Ticket> get unusedTickets => 
      _tickets.where((t) => !t.estUtilise).toList();
  
  List<Ticket> get usedTickets => 
      _tickets.where((t) => t.estUtilise).toList();
  
  List<Amende> get unpaidAmendes => 
      _amendes.where((a) => !a.estPayee).toList();
  
  List<Amende> get paidAmendes => 
      _amendes.where((a) => a.estPayee).toList();
  
  double get totalUnpaidAmendes => 
      unpaidAmendes.fold(0.0, (sum, a) => sum + a.montant);
  
  bool get hasActiveAbonnement => _activeAbonnement != null;
  
  bool get hasValidTitle => hasActiveAbonnement || validTickets.isNotEmpty;
  
  /// Initialize provider with user ID
  void initialize(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    loadAllData();
  }
  
  /// Clear data when user logs out
  void clear() {
    _userId = null;
    _tickets = [];
    _abonnements = [];
    _amendes = [];
    _activeAbonnement = null;
    _state = CommercialLoadingState.initial;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Load all commercial data for the user
  Future<void> loadAllData() async {
    if (_userId == null) return;
    
    try {
      _state = CommercialLoadingState.loading;
      _errorMessage = null;
      notifyListeners();
      
      await Future.wait([
        _loadTickets(),
        _loadAbonnements(),
        _loadAmendes(),
        _loadActiveAbonnement(),
      ]);
      
      _state = CommercialLoadingState.loaded;
    } catch (e) {
      debugPrint('Error loading commercial data: $e');
      _errorMessage = 'Erreur lors du chargement des données';
      _state = CommercialLoadingState.error;
    }
    notifyListeners();
  }
  
  /// Load tickets
  Future<void> _loadTickets() async {
    if (_userId == null) return;
    final data = await _supabase.getTicketsForUser(_userId!);
    _tickets = data.map((json) => Ticket.fromJson(json)).toList();
  }
  
  /// Load abonnements
  Future<void> _loadAbonnements() async {
    if (_userId == null) return;
    final data = await _supabase.getAbonnementsForUser(_userId!);
    _abonnements = data.map((json) => Abonnement.fromJson(json)).toList();
  }
  
  /// Load amendes
  Future<void> _loadAmendes() async {
    if (_userId == null) return;
    final data = await _supabase.getAmendesForUser(_userId!);
    _amendes = data.map((json) => Amende.fromJson(json)).toList();
  }
  
  /// Load active abonnement
  Future<void> _loadActiveAbonnement() async {
    if (_userId == null) return;
    final data = await _supabase.getActiveAbonnement(_userId!);
    _activeAbonnement = data != null ? Abonnement.fromJson(data) : null;
  }
  
  // ==================== TICKET OPERATIONS ====================
  
  /// Purchase a ticket
  Future<Ticket?> purchaseTicket({
    required String type,
    required double prix,
  }) async {
    if (_userId == null) return null;
    
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final ticketData = Ticket.forPurchase(
        userId: _userId!,
        type: type,
        prix: prix,
      );
      
      final response = await _supabase.createTicket(ticketData);
      final newTicket = Ticket.fromJson(response);
      _tickets.insert(0, newTicket);
      
      _isProcessing = false;
      notifyListeners();
      return newTicket;
    } catch (e) {
      debugPrint('Error purchasing ticket: $e');
      _errorMessage = 'Erreur lors de l\'achat du ticket';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Validate (compost) a ticket
  Future<bool> validateTicket(String ticketId) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _supabase.validateTicket(ticketId);
      final updatedTicket = Ticket.fromJson(response);
      
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = updatedTicket;
      }
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error validating ticket: $e');
      _errorMessage = 'Erreur lors de la validation du ticket';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Get ticket by ID
  Ticket? getTicketById(String ticketId) {
    try {
      return _tickets.firstWhere((t) => t.id == ticketId);
    } catch (e) {
      return null;
    }
  }
  
  // ==================== ABONNEMENT OPERATIONS ====================
  
  /// Purchase an abonnement
  Future<Abonnement?> purchaseAbonnement({
    required String type,
    required int durationMonths,
  }) async {
    if (_userId == null) return null;
    
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final abonnementData = Abonnement.forPurchase(
        userId: _userId!,
        type: type,
        durationMonths: durationMonths,
      );
      
      final response = await _supabase.createAbonnement(abonnementData);
      final newAbonnement = Abonnement.fromJson(response);
      _abonnements.insert(0, newAbonnement);
      
      // Update active abonnement if this one is active
      if (newAbonnement.estActif) {
        _activeAbonnement = newAbonnement;
      }
      
      _isProcessing = false;
      notifyListeners();
      return newAbonnement;
    } catch (e) {
      debugPrint('Error purchasing abonnement: $e');
      _errorMessage = 'Erreur lors de l\'achat de l\'abonnement';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Check if user has a valid travel title
  Future<bool> hasValidTravelTitle() async {
    // Check active abonnement
    if (_activeAbonnement != null && _activeAbonnement!.estActif) {
      return true;
    }
    
    // Check valid tickets
    final validTickets = _tickets.where((t) => t.estValide).toList();
    return validTickets.isNotEmpty;
  }
  
  // ==================== AMENDE OPERATIONS ====================
  
  /// Pay an amende
  Future<bool> payAmende(String amendeId) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _supabase.payAmende(amendeId);
      final updatedAmende = Amende.fromJson(response);
      
      final index = _amendes.indexWhere((a) => a.id == amendeId);
      if (index != -1) {
        _amendes[index] = updatedAmende;
      }
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error paying amende: $e');
      _errorMessage = 'Erreur lors du paiement de l\'amende';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Create an amende (for controleurs)
  Future<Amende?> createAmende({
    required String userId,
    required String controleurId,
    required double montant,
    required String motif,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final amendeData = Amende.forCreation(
        userId: userId,
        controleurId: controleurId,
        montant: montant,
        motif: motif,
      );
      
      final response = await _supabase.createAmende(amendeData);
      final newAmende = Amende.fromJson(response);
      
      _isProcessing = false;
      notifyListeners();
      return newAmende;
    } catch (e) {
      debugPrint('Error creating amende: $e');
      _errorMessage = 'Erreur lors de la création de l\'amende';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  /// Refresh all data
  Future<void> refresh() async {
    await loadAllData();
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Get ticket price based on type
  static double getTicketPrice(String type) {
    switch (type.toLowerCase()) {
      case 'unitaire':
        return 50.0;  // 50 DA
      case 'carnet':
        return 400.0; // 400 DA (10 tickets)
      case 'navigo_jour':
        return 150.0; // 150 DA
      case 'aller_retour':
        return 90.0;  // 90 DA
      default:
        return 50.0;
    }
  }
  
  /// Get abonnement price based on type and duration
  static double getAbonnementPrice(String type, int durationMonths) {
    double basePrice;
    switch (type.toLowerCase()) {
      case 'standard':
        basePrice = 2000.0; // 2000 DA/month
        break;
      case 'etudiant':
        basePrice = 1000.0; // 1000 DA/month
        break;
      case 'senior':
        basePrice = 1200.0; // 1200 DA/month
        break;
      case 'famille':
        basePrice = 3500.0; // 3500 DA/month
        break;
      default:
        basePrice = 2000.0;
    }
    
    // Apply discount for longer duration
    if (durationMonths >= 12) {
      return basePrice * durationMonths * 0.8; // 20% discount
    } else if (durationMonths >= 6) {
      return basePrice * durationMonths * 0.9; // 10% discount
    }
    return basePrice * durationMonths;
  }
}
