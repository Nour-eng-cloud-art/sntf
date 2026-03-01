import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/providers/auth_provider.dart';
import 'package:sntf/ui/widgets/animated_text_field.dart';
import 'package:sntf/ui/widgets/animated_button.dart';
import 'package:sntf/ui/widgets/train_animation.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _rememberMe = false;

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _fadeController.forward();
    _slideController.forward();
    
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey) ?? '';
    
    if (rememberMe && savedEmail.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_savedEmailKey);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      setState(() => _isLoading = false);
      print('Login success: $success');
      if (success && mounted) {
        await _saveCredentials();
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        authProvider.clearError();
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(email);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Un email de réinitialisation a été envoyé'
              : authProvider.errorMessage ?? 'Erreur lors de l\'envoi',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (!success) authProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Logo
                        const AnimatedLogo(size: 100),
                        
                        const SizedBox(height: 40),
                        
                        // Welcome Text
                        Text(
                          'Bon retour !',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour continuer',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        
                        AnimatedTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'votre@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          animationIndex: 1,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        AnimatedTextField(
                          controller: _passwordController,
                          label: 'Mot de passe',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          animationIndex: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Remember me & Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() => _rememberMe = value ?? false);
                                    },
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Se souvenir de moi',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                _handleForgotPassword();
                              },
                              child: Text(
                                'Mot de passe oublié ?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Login Button
                        AnimatedButton(
                          text: 'Se connecter',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          icon: Icons.login_rounded,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous n'avez pas de compte ? ",
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signin');
                              },
                              child: Text(
                                "S'inscrire",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Track decoration
                        const TrackDecoration(),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}