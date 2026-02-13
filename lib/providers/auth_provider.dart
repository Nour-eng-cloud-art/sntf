import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sntf/data/models/user.dart';
import 'package:sntf/data/services/supabase_service.dart';

/// Authentication state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// AuthProvider manages user authentication state and profile data
class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  // State
  AuthStatus _status = AuthStatus.initial;
  AppUser? _user;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;
  
  // Getters
  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  String? get userId => _user?.id;
  
  AuthProvider() {
    _initialize();
  }
  
  /// Initialize auth state and listen for changes
  void _initialize() {
    // Check current session
    final session = _supabase.currentSession;
    if (session != null) {
      _loadUserProfile(session.user.id);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
    
    // Listen for auth state changes
    _authSubscription = _supabase.authStateChanges.listen((AuthState state) {
      final event = state.event;
      final session = state.session;
      
      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            _loadUserProfile(session.user.id);
          }
          break;
        case AuthChangeEvent.signedOut:
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          break;
        case AuthChangeEvent.tokenRefreshed:
          // Token refreshed, user still logged in
          break;
        case AuthChangeEvent.userUpdated:
          if (session != null) {
            _loadUserProfile(session.user.id);
          }
          break;
        default:
          break;
      }
    });
  }
  
  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      
      final profileData = await _supabase.getProfile(userId);
      
      if (profileData != null) {
        _user = AppUser.fromJson(profileData);
        _status = AuthStatus.authenticated;
      } else {
        // Profile doesn't exist yet, create it
        final authUser = _supabase.currentUser;
        if (authUser != null) {
          final newProfile = {
            'id': authUser.id,
            'email': authUser.email,
            'role': 'client',
          };
          await _supabase.upsertProfile(newProfile);
          _user = AppUser.fromJson(newProfile);
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _errorMessage = 'Erreur lors du chargement du profil';
      _status = AuthStatus.error;
    }
    notifyListeners();
  }
  
  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    DateTime? dateNaissance,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _supabase.signUp(
        email: email,
        password: password,
        data: {
          'nom': nom,
          'prenom': prenom,
        },
      );
      
      if (response.user != null) {
        // Create profile in database
        final profile = {
          'id': response.user!.id,
          'email': email,
          'nom': nom,
          'prenom': prenom,
          'role': 'client',
          'date_naissance': dateNaissance?.toIso8601String().split('T')[0],
        };
        
        await _supabase.upsertProfile(profile);
        _user = AppUser.fromJson(profile);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Erreur lors de l\'inscription';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue s\'est produite';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return _status == AuthStatus.authenticated;
      } else {
        _errorMessage = 'Erreur lors de la connexion';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue s\'est produite';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
    }
    notifyListeners();
  }
  
  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _supabase.resetPassword(email);
      
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue s\'est produite';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      await _supabase.updatePassword(newPassword);
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue s\'est produite';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateProfile({
    String? nom,
    String? prenom,
    String? photoUrl,
    DateTime? dateNaissance,
  }) async {
    if (_user == null) return false;
    
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      final updates = <String, dynamic>{};
      if (nom != null) updates['nom'] = nom;
      if (prenom != null) updates['prenom'] = prenom;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      if (dateNaissance != null) {
        updates['date_naissance'] = dateNaissance.toIso8601String().split('T')[0];
      }
      
      if (updates.isNotEmpty) {
        final updatedProfile = await _supabase.updateProfile(_user!.id, updates);
        _user = AppUser.fromJson(updatedProfile);
      }
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour du profil';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Refresh user profile from database
  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadUserProfile(_user!.id);
    }
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  
  /// Translate auth error messages to French
  String _translateAuthError(String message) {
    final errorMap = {
      'Invalid login credentials': 'Email ou mot de passe incorrect',
      'Email not confirmed': 'Veuillez confirmer votre email',
      'User already registered': 'Un compte existe déjà avec cet email',
      'Password should be at least 6 characters': 
          'Le mot de passe doit contenir au moins 6 caractères',
      'Unable to validate email address: invalid format':
          'Format d\'email invalide',
      'Email rate limit exceeded':
          'Trop de tentatives, veuillez réessayer plus tard',
      'For security purposes, you can only request this once every 60 seconds':
          'Pour des raisons de sécurité, attendez 60 secondes avant de réessayer',
    };
    
    return errorMap[message] ?? 'Une erreur s\'est produite: $message';
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
