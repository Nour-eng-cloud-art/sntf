import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
            'date_naissance': null,
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
    required String phone,
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
          'phone': phone,
          'date_naissance': dateNaissance?.toIso8601String().split('T')[0],
        },
      );
      
      if (response.user != null) {
        
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
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Check if we're on mobile (Android/iOS) or desktop/web
      final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      
      if (isMobile) {
        // Use native Google Sign-In on mobile
        return await _signInWithGoogleNative();
      } else {
        // Use web OAuth flow on desktop/web
        return await _signInWithGoogleWeb();
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _errorMessage = 'Erreur Google: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> _signInWithGoogleNative() async {
    // Get the Web Client ID from environment
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (webClientId == null || webClientId.isEmpty || webClientId.contains('YOUR_')) {
      _errorMessage = 'Google Sign-In non configuré. Veuillez ajouter GOOGLE_WEB_CLIENT_ID dans .env';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    
    // Use native Google Sign-In with serverClientId for idToken
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: webClientId,
    );
      
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false; // User cancelled
    }
    
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    
    if (idToken == null) {
      _errorMessage = 'Erreur lors de la connexion Google';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    
    final response = await _supabase.signInWithGoogleIdToken(
      idToken: idToken,
      accessToken: accessToken,
    );
    
    if (response.user != null) {
      await _loadUserProfile(response.user!.id);
      return _status == AuthStatus.authenticated;
    } else {
      _errorMessage = 'Erreur lors de la connexion Google';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Web OAuth flow for Google Sign-In (desktop/web)
  Future<bool> _signInWithGoogleWeb() async {
    try {
      // Use Supabase OAuth redirect flow
      final success = await _supabase.signInWithOAuth(OAuthProvider.google);
      
      if (!success) {
        _errorMessage = 'Erreur lors de la connexion Google';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      
      // Wait for auth state to change (user logs in via browser)
      // The auth state listener will handle the rest
      return true;
    } on AuthException catch (e) {
      debugPrint('Google web sign in AuthException: ${e.message}');
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      
      // Check if we're on mobile (iOS/macOS) or desktop/web
      final bool isAppleNativeSupported = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
      
      if (isAppleNativeSupported) {
        return await _signInWithAppleNative();
      } else {
        // Use web OAuth flow on non-Apple platforms
        return await _signInWithAppleWeb();
      }
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      _errorMessage = 'Erreur Apple: ${e.toString().length > 100 ? e.toString().substring(0, 100) : e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Native Apple Sign-In for iOS/macOS
  Future<bool> _signInWithAppleNative() async {
    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    
    final idToken = credential.identityToken;
    if (idToken == null) {
      _errorMessage = 'Erreur lors de la connexion Apple';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    
    final response = await _supabase.signInWithAppleIdToken(
      idToken: idToken,
      nonce: rawNonce,
    );
    
    if (response.user != null) {
      await _loadUserProfile(response.user!.id);
      return _status == AuthStatus.authenticated;
    } else {
      _errorMessage = 'Erreur lors de la connexion Apple';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Web OAuth flow for Apple Sign-In
  Future<bool> _signInWithAppleWeb() async {
    try {
      // Use Supabase OAuth redirect flow
      final success = await _supabase.signInWithOAuth(OAuthProvider.apple);
      
      if (!success) {
        _errorMessage = 'Erreur lors de la connexion Apple';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      
      // The auth state listener will handle the rest
      return true;
    } on AuthException catch (e) {
      debugPrint('Apple web sign in AuthException: ${e.message}');
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }
  
  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
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
