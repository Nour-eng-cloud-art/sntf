import 'package:flutter/foundation.dart';
import 'package:sntf/data/models/incident.dart';
import 'package:sntf/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loading state for incident operations
enum IncidentLoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// IncidentProvider manages pannes (breakdowns/incidents)
class IncidentProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  // State
  IncidentLoadingState _state = IncidentLoadingState.initial;
  String? _errorMessage;
  bool _isProcessing = false;
  
  // Data
  List<Panne> _pannes = [];
  List<Panne> _activePannes = [];
  
  // Real-time subscription
  RealtimeChannel? _pannesChannel;
  
  // Getters
  IncidentLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == IncidentLoadingState.loading;
  bool get isProcessing => _isProcessing;
  bool get hasError => _state == IncidentLoadingState.error;
  
  List<Panne> get pannes => _pannes;
  List<Panne> get activePannes => _activePannes;
  
  // Filtered getters
  List<Panne> get resolvedPannes => 
      _pannes.where((p) => p.estResolu).toList();
  
  List<Panne> get recentPannes => 
      _pannes.where((p) => p.estRecent).toList();
  
  int get activePannesCount => _activePannes.length;
  
  IncidentProvider() {
    loadAllData();
  }
  
  /// Load all incident data
  Future<void> loadAllData() async {
    try {
      _state = IncidentLoadingState.loading;
      _errorMessage = null;
      notifyListeners();
      
      await Future.wait([
        _loadAllPannes(),
        _loadActivePannes(),
      ]);
      
      _state = IncidentLoadingState.loaded;
    } catch (e) {
      debugPrint('Error loading incident data: $e');
      _errorMessage = 'Erreur lors du chargement des incidents';
      _state = IncidentLoadingState.error;
    }
    notifyListeners();
  }
  
  /// Load all pannes
  Future<void> _loadAllPannes() async {
    final data = await _supabase.getPannes();
    _pannes = data.map((json) => Panne.fromJson(json)).toList();
  }
  
  /// Load active (unresolved) pannes
  Future<void> _loadActivePannes() async {
    final data = await _supabase.getActivePannes();
    _activePannes = data.map((json) => Panne.fromJson(json)).toList();
  }
  
  /// Get pannes for a specific vehicule
  Future<List<Panne>> getPannesForVehicule(String vehiculeId) async {
    try {
      final data = await _supabase.getPannesForVehicule(vehiculeId);
      return data.map((json) => Panne.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading pannes for vehicule: $e');
      return [];
    }
  }
  
  /// Report a new panne
  Future<Panne?> reportPanne({
    required String vehiculeId,
    required String description,
  }) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final panneData = Panne.forReport(
        vehiculeId: vehiculeId,
        description: description,
      );
      
      final response = await _supabase.reportPanne(panneData);
      final newPanne = Panne.fromJson(response);
      
      _pannes.insert(0, newPanne);
      _activePannes.insert(0, newPanne);
      
      _isProcessing = false;
      notifyListeners();
      return newPanne;
    } catch (e) {
      debugPrint('Error reporting panne: $e');
      _errorMessage = 'Erreur lors du signalement de la panne';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Resolve a panne
  Future<bool> resolvePanne(String panneId) async {
    try {
      _isProcessing = true;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _supabase.resolvePanne(panneId);
      final updatedPanne = Panne.fromJson(response);
      
      // Update in all pannes list
      final index = _pannes.indexWhere((p) => p.id == panneId);
      if (index != -1) {
        _pannes[index] = updatedPanne;
      }
      
      // Remove from active pannes
      _activePannes.removeWhere((p) => p.id == panneId);
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resolving panne: $e');
      _errorMessage = 'Erreur lors de la résolution de la panne';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Check if a ligne has active pannes
  bool ligneHasActivePannes(String ligneId) {
    return _activePannes.any((p) => 
        p.vehicule?.ligneId == ligneId);
  }
  
  /// Get active pannes for a ligne
  List<Panne> getActivePannesForLigne(String ligneId) {
    return _activePannes.where((p) => 
        p.vehicule?.ligneId == ligneId).toList();
  }
  
  /// Subscribe to real-time panne updates
  void subscribeToUpdates() {
    _pannesChannel?.unsubscribe();
    
    _pannesChannel = _supabase.subscribeToTable(
      'pannes',
      onInsert: (payload) {
        final newPanne = Panne.fromJson(payload.newRecord);
        _pannes.insert(0, newPanne);
        if (!newPanne.estResolu) {
          _activePannes.insert(0, newPanne);
        }
        notifyListeners();
      },
      onUpdate: (payload) {
        final updatedPanne = Panne.fromJson(payload.newRecord);
        
        // Update in pannes list
        final index = _pannes.indexWhere((p) => p.id == updatedPanne.id);
        if (index != -1) {
          _pannes[index] = updatedPanne;
        }
        
        // Handle active pannes
        if (updatedPanne.estResolu) {
          _activePannes.removeWhere((p) => p.id == updatedPanne.id);
        } else {
          final activeIndex = _activePannes.indexWhere((p) => p.id == updatedPanne.id);
          if (activeIndex != -1) {
            _activePannes[activeIndex] = updatedPanne;
          } else {
            _activePannes.insert(0, updatedPanne);
          }
        }
        
        notifyListeners();
      },
      onDelete: (payload) {
        final deletedId = payload.oldRecord['id'];
        _pannes.removeWhere((p) => p.id == deletedId);
        _activePannes.removeWhere((p) => p.id == deletedId);
        notifyListeners();
      },
    );
  }
  
  /// Unsubscribe from real-time updates
  void unsubscribeFromUpdates() {
    if (_pannesChannel != null) {
      _supabase.unsubscribe(_pannesChannel!);
      _pannesChannel = null;
    }
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await loadAllData();
  }
  
  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    unsubscribeFromUpdates();
    super.dispose();
  }
}
