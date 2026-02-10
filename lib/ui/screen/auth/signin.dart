import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sntf/core/theme/app_colors.dart';
import 'package:sntf/data/models/user.dart';
import 'package:sntf/ui/widgets/animated_text_field.dart';
import 'package:sntf/ui/widgets/animated_button.dart';
import 'package:sntf/ui/widgets/train_animation.dart';


class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controllers for all fields
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _codePostalController = TextEditingController();
  final _numeroCarteController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  bool _isLoading = false;
  bool _acceptTerms = false;
  int _currentStep = 0;
  static const int _totalSteps = 5;

  // User data
  DateTime? _dateNaissance;
  Genre _selectedGenre = Genre.nonSpecifie;
  String? _selectedWilaya;
  String? _selectedVille;
  CarteReduction _selectedCarte = CarteReduction.aucune;
  bool _notificationsActives = true;
  bool _emailsPromotionnels = false;

  final Map<String, List<String>> _wilayaCities = {
    'Adrar': ['Adrar', 'Reggane', 'Aoulef', 'Timimoun', 'Bordj Badji Mokhtar', 'Tsabit', 'Fenoughil', 'Zaouiet Kounta'],
    'Chlef': ['Chlef', 'Ténès', 'El Karimia', 'Oued Fodda', 'Boukadir', 'Chettia', 'Aïn Merane', 'Ouled Fares'],
    'Laghouat': ['Laghouat', 'Aflou', 'Ksar El Hirane', 'Hassi R\'Mel', 'Aïn Mahdi', 'Brida', 'Gueltat Sidi Saad'],
    'Oum El Bouaghi': ['Oum El Bouaghi', 'Aïn Beïda', 'Aïn M\'Lila', 'Meskiana', 'Sigus', 'Aïn Fakroun', 'Ksar Sbahi'],
    'Batna': ['Batna', 'Barika', 'N\'Gaous', 'Aïn Touta', 'Merouana', 'Arris', 'Tazoult', 'Timgad', 'El Madher'],
    'Béjaïa': ['Béjaïa', 'Akbou', 'El Kseur', 'Sidi Aïch', 'Amizour', 'Kherrata', 'Tichy', 'Aokas', 'Souk El Ténine'],
    'Biskra': ['Biskra', 'Tolga', 'Ouled Djellal', 'Sidi Okba', 'El Kantara', 'Djemorah', 'Zeribet El Oued', 'Foughala'],
    'Béchar': ['Béchar', 'Kenadsa', 'Abadla', 'Beni Ounif', 'Taghit', 'Igli', 'Lahmar', 'Béni Abbès'],
    'Blida': ['Blida', 'Boufarik', 'El Affroun', 'Mouzaïa', 'Oued El Alleug', 'Bougara', 'Larbaâ', 'Chréa', 'Bouinan'],
    'Bouira': ['Bouira', 'Lakhdaria', 'Sour El Ghozlane', 'M\'Chedallah', 'Kadiria', 'Bordj Okhriss', 'Aïn Bessem', 'Haizer'],
    'Tamanrasset': ['Tamanrasset', 'In Salah', 'In Guezzam', 'Abalessa', 'Idlès', 'Tazrouk', 'In Amguel'],
    'Tébessa': ['Tébessa', 'Bir El Ater', 'Cheria', 'El Aouinet', 'Morsott', 'El Kouif', 'Ouenza', 'El Ma El Abiod'],
    'Tlemcen': ['Tlemcen', 'Maghnia', 'Ghazaouet', 'Remchi', 'Nedroma', 'Sebdou', 'Hennaya', 'Mansourah', 'Beni Snous'],
    'Tiaret': ['Tiaret', 'Frenda', 'Sougueur', 'Mahdia', 'Aïn Deheb', 'Ksar Chellala', 'Rahouia', 'Oued Lilli'],
    'Tizi Ouzou': ['Tizi Ouzou', 'Azazga', 'Draâ El Mizan', 'Larbaâ Nath Irathen', 'Aïn El Hammam', 'Boghni', 'Makouda', 'Ouaguenoun', 'Tigzirt'],
    'Alger': ['Alger Centre', 'Bab El Oued', 'Hussein Dey', 'Kouba', 'El Harrach', 'Bir Mourad Raïs', 'Bouzareah', 'Chéraga', 'Draria', 'Rouiba', 'Dar El Beïda', 'Bab Ezzouar', 'Dély Ibrahim', 'Hydra', 'El Biar'],
    'Djelfa': ['Djelfa', 'Messaad', 'Aïn Oussera', 'Hassi Bahbah', 'Charef', 'Birine', 'Moudjebara', 'Had Sahary'],
    'Jijel': ['Jijel', 'El Milia', 'Taher', 'Chekfa', 'Texenna', 'Ziama Mansouriah', 'Settara', 'El Aouana'],
    'Sétif': ['Sétif', 'El Eulma', 'Aïn Oulmène', 'Aïn Arnat', 'Bougaa', 'Aïn El Kebira', 'Djemila', 'Bouandas', 'Béni Aziz'],
    'Saïda': ['Saïda', 'Aïn El Hadjar', 'Youb', 'Ouled Brahim', 'Hassasna', 'Sidi Boubekeur', 'El Hassasna'],
    'Skikda': ['Skikda', 'Collo', 'Azzaba', 'El Harrouch', 'Tamalous', 'Ramdane Djamel', 'Aïn Kechra', 'Ben Azzouz'],
    'Sidi Bel Abbès': ['Sidi Bel Abbès', 'Telagh', 'Ben Badis', 'Aïn El Berd', 'Sfissef', 'Tessala', 'Mostefa Ben Brahim', 'Sidi Ali Benyoub'],
    'Annaba': ['Annaba', 'El Bouni', 'Berrahal', 'El Hadjar', 'Aïn Berda', 'Chétaïbi', 'Seraïdi', 'Sidi Amar'],
    'Guelma': ['Guelma', 'Bouchegouf', 'Oued Zenati', 'Héliopolis', 'Hammam Debagh', 'Hammam N\'Bails', 'Khezaras'],
    'Constantine': ['Constantine', 'El Khroub', 'Aïn Smara', 'Hamma Bouziane', 'Didouche Mourad', 'Zighoud Youcef', 'Ibn Ziad', 'Aïn Abid'],
    'Médéa': ['Médéa', 'Berrouaghia', 'Ksar El Boukhari', 'Tablat', 'Beni Slimane', 'Aïn Boucif', 'Chahbounia', 'Ouamri'],
    'Mostaganem': ['Mostaganem', 'Aïn Tedles', 'Sidi Ali', 'Achaacha', 'Hassi Mameche', 'Mazagran', 'Aïn Nouïssy', 'Mesra'],
    'M\'Sila': ['M\'Sila', 'Bou Saâda', 'Aïn El Melh', 'Sidi Aïssa', 'Hammam Dalaa', 'Magra', 'Ouled Derradj', 'Khoubana'],
    'Mascara': ['Mascara', 'Sig', 'Mohammadia', 'Tighennif', 'Ghriss', 'Bouhanifia', 'Aïn Fares', 'Oued El Abtal'],
    'Ouargla': ['Ouargla', 'Hassi Messaoud', 'Touggourt', 'Taibet', 'Témacine', 'Megarine', 'N\'Goussa', 'El Hadjira'],
    'Oran': ['Oran', 'Bir El Djir', 'Es Sénia', 'Arzew', 'Aïn El Turk', 'Bethioua', 'Gdyel', 'Oued Tlelat', 'Bousfer', 'Mers El Kébir'],
    'El Bayadh': ['El Bayadh', 'Bougtob', 'Brezina', 'El Abiodh Sidi Cheikh', 'Boualem', 'Rogassa', 'Aïn El Orak'],
    'Illizi': ['Illizi', 'Djanet', 'In Amenas', 'Bordj Omar Driss', 'Debdeb'],
    'Bordj Bou Arréridj': ['Bordj Bou Arréridj', 'Ras El Oued', 'Bordj Zemoura', 'El Achir', 'Medjana', 'Djaafra', 'Bordj Ghedir', 'Mansourah'],
    'Boumerdès': ['Boumerdès', 'Bordj Menaïel', 'Dellys', 'Khemis El Khechna', 'Boudouaou', 'Thénia', 'Isser', 'Naciria', 'Tidjelabine'],
    'El Tarf': ['El Tarf', 'El Kala', 'Bouhadjar', 'Ben M\'Hidi', 'Dréan', 'Besbes', 'Bouteldja', 'Lac des Oiseaux'],
    'Tindouf': ['Tindouf', 'Oum El Assel'],
    'Tissemsilt': ['Tissemsilt', 'Theniet El Had', 'Bordj Bou Naama', 'Lazharia', 'Khemisti', 'Lardjem', 'Ammari'],
    'El Oued': ['El Oued', 'Guemar', 'Robbah', 'Debila', 'Bayadha', 'Hassani Abdelkrim', 'Taleb Larbi', 'Magrane'],
    'Khenchela': ['Khenchela', 'Kaïs', 'Chechar', 'El Hamma', 'Aïn Touila', 'Babar', 'Bouhmama', 'Ouled Rechache'],
    'Souk Ahras': ['Souk Ahras', 'Sedrata', 'M\'Daourouch', 'Taoura', 'Hanancha', 'Mechroha', 'Ouled Driss', 'Bir Bouhouche'],
    'Tipaza': ['Tipaza', 'Koléa', 'Cherchell', 'Hadjout', 'Bou Ismaïl', 'Fouka', 'Gouraya', 'Damous', 'Sidi Amar'],
    'Mila': ['Mila', 'Ferdjioua', 'Chelghoum Laïd', 'Tadjenanet', 'Grarem Gouga', 'Oued Athmania', 'Sidi Merouane', 'Teleghma'],
    'Aïn Defla': ['Aïn Defla', 'Miliana', 'Khemis Miliana', 'El Attaf', 'Djelida', 'Bordj Emir Khaled', 'Aïn Lechiakh', 'Hammam Righa'],
    'Naâma': ['Naâma', 'Mécheria', 'Aïn Sefra', 'Tiout', 'Moghrar', 'Asla', 'Sfissifa'],
    'Aïn Témouchent': ['Aïn Témouchent', 'El Malah', 'Beni Saf', 'Hammam Bou Hadjar', 'El Amria', 'Aïn El Arbaa', 'Oulhaça'],
    'Ghardaïa': ['Ghardaïa', 'Metlili', 'El Guerrara', 'Berriane', 'Zelfana', 'Bounoura', 'El Atteuf', 'Dhayet Ben Dhahoua'],
    'Relizane': ['Relizane', 'Oued Rhiou', 'Mazouna', 'Djidioua', 'Aïn Tarek', 'Yellel', 'Mendes', 'Zemmora'],
  };

  // Get list of wilayas (keys from the map)
  List<String> get _wilayas => _wilayaCities.keys.toList();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Add listener to update password strength in real-time
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _adresseController.dispose();
    _codePostalController.dispose();
    _numeroCarteController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _handleSignup();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Welcome
        return true;
      case 1: // Basic Info
        return _validateBasicInfo();
      case 2: // Personal Details
        return _validatePersonalDetails();
      case 3: // Travel Preferences
        return true; // Optional step
      case 4: // Security
        return _validateSecurity();
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    if (_nomController.text.isEmpty) {
      _showError('Veuillez entrer votre nom');
      return false;
    }
    if (_prenomController.text.isEmpty) {
      _showError('Veuillez entrer votre prénom');
      return false;
    }
    if (_emailController.text.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showError('Veuillez entrer un email valide');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Veuillez entrer votre numéro de téléphone');
      return false;
    }
    return true;
  }

  bool _validatePersonalDetails() {
    // Date de naissance is recommended but not required
    return true;
  }

  bool _validateSecurity() {
    if (_passwordController.text.isEmpty) {
      _showError('Veuillez entrer un mot de passe');
      return false;
    }
    if (_passwordController.text.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caractères');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return false;
    }
    if (!_acceptTerms) {
      _showError('Veuillez accepter les conditions d\'utilisation');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    setState(() => _isLoading = true);

    // Simulate signup process
    await Future.delayed(const Duration(seconds: 2));

    // Create the user object (in real app, send to backend)
    final userData = {
      'nom': _nomController.text,
      'prenom': _prenomController.text,
      'email': _emailController.text,
      'telephone': _phoneController.text,
      'date_naissance': _dateNaissance?.toIso8601String(),
      'genre': _selectedGenre.toString().split('.').last,
      'adresse': _adresseController.text,
      'ville': _selectedVille,
      'code_postal': _codePostalController.text,
      'wilaya': _selectedWilaya,
      'carte_reduction': _selectedCarte.toString().split('.').last,
      'numero_carte_reduction': _numeroCarteController.text,
      'notifications_actives': _notificationsActives,
      'emails_promotionnels': _emailsPromotionnels,
    };

    debugPrint('User data: $userData');

    setState(() => _isLoading = false);

    if (mounted) {
      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 50,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenue ${_prenomController.text} !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre compte a été créé avec succès.\nVous pouvez maintenant profiter de tous les services SNTF.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedButton(
                text: 'Commencer',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _AnimatedBackButton(onPressed: _previousStep),
                      const Spacer(),
                      _ProgressIndicator(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(),
                      _buildBasicInfoStep(),
                      _buildPersonalDetailsStep(),
                      _buildTravelPreferencesStep(),
                      _buildSecurityStep(),
                    ],
                  ),
                ),

                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildBottomButtons(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const AnimatedLogo(size: 120),
          const SizedBox(height: 40),
          Text(
            'Créer votre compte voyageur',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Rejoignez la communauté SNTF et profitez de nombreux avantages pour vos voyages en train à travers l\'Algérie.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Benefits cards
          _BenefitCard(
            icon: Icons.confirmation_number_rounded,
            title: 'Réservation facile',
            description: 'Réservez vos billets en quelques clics',
          ),
          const SizedBox(height: 12),
          _BenefitCard(
            icon: Icons.loyalty_rounded,
            title: 'Programme fidélité',
            description: 'Cumulez des points à chaque voyage',
          ),
          const SizedBox(height: 12),
          _BenefitCard(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications en temps réel',
            description: 'Restez informé de l\'état de vos trains',
          ),
          const SizedBox(height: 12),
          _BenefitCard(
            icon: Icons.discount_rounded,
            title: 'Offres exclusives',
            description: 'Accédez à des promotions réservées aux membres',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Icon(
                Icons.person_add_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Informations de base',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ces informations apparaîtront sur vos billets de train',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Nom
            AnimatedTextField(
              controller: _nomController,
              label: 'Nom de famille',
              hint: 'BENSALEM',
              prefixIcon: Icons.badge_outlined,
              animationIndex: 1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Prénom
            AnimatedTextField(
              controller: _prenomController,
              label: 'Prénom',
              hint: 'Ahmed',
              prefixIcon: Icons.person_outline_rounded,
              animationIndex: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            AnimatedTextField(
              controller: _emailController,
              label: 'Adresse email',
              hint: 'ahmed.bensalem@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              animationIndex: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            AnimatedTextField(
              controller: _phoneController,
              label: 'Numéro de téléphone',
              hint: '0555 12 34 56',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              animationIndex: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.assignment_ind_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Informations personnelles',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ces informations sont optionnelles mais recommandées',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Date de naissance
          Text(
            'Date de naissance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _dateNaissance != null
                        ? '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}'
                        : 'Sélectionner une date',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _dateNaissance != null
                          ? theme.colorScheme.onSurface
                          : (isDark ? AppColors.grey500 : AppColors.grey600),
                    ),
                  ),
                  const Spacer(),
                  if (_dateNaissance != null)
                    _AgeBadge(dateNaissance: _dateNaissance!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Genre
          Text(
            'Genre',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: Genre.values.map((genre) {
              final isSelected = _selectedGenre == genre;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: genre != Genre.values.last ? 8 : 0,
                  ),
                  child: _SelectableChip(
                    label: _getGenreLabel(genre),
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedGenre = genre),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Wilaya
          Text(
            'Wilaya',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWilaya,
                hint: Text(
                  'Sélectionner votre wilaya',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? AppColors.grey400 : AppColors.grey600,
                ),
                items: _wilayas.map((wilaya) {
                  return DropdownMenuItem(
                    value: wilaya,
                    child: Text(wilaya),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _selectedWilaya = value;
                  _selectedVille = null; // Reset city when wilaya changes
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ville (Commune)
          Text(
            'Commune',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVille,
                hint: Text(
                  _selectedWilaya == null
                      ? 'Sélectionnez d\'abord une wilaya'
                      : 'Sélectionner votre commune',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _selectedWilaya == null
                      ? (isDark ? AppColors.grey600 : AppColors.grey400)
                      : (isDark ? AppColors.grey400 : AppColors.grey600),
                ),
                items: _selectedWilaya == null
                    ? []
                    : _wilayaCities[_selectedWilaya]!.map((ville) {
                        return DropdownMenuItem(
                          value: ville,
                          child: Text(ville),
                        );
                      }).toList(),
                onChanged: _selectedWilaya == null
                    ? null
                    : (value) => setState(() => _selectedVille = value),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Adresse
          AnimatedTextField(
            controller: _adresseController,
            label: 'Adresse (optionnel)',
            hint: 'Rue, Numéro, Quartier',
            prefixIcon: Icons.home_outlined,
            animationIndex: 2,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTravelPreferencesStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.card_membership_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Préférences de voyage',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personnalisez votre expérience de voyage',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Carte de réduction
          Text(
            'Carte de réduction',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CarteReduction.values.map((carte) {
              final isSelected = _selectedCarte == carte;
              return _SelectableChip(
                label: _getCarteLabel(carte),
                isSelected: isSelected,
                onTap: () => setState(() => _selectedCarte = carte),
                icon: _getCarteIcon(carte),
              );
            }).toList(),
          ),

          if (_selectedCarte != CarteReduction.aucune) ...[
            const SizedBox(height: 16),
            AnimatedTextField(
              controller: _numeroCarteController,
              label: 'Numéro de carte',
              hint: 'XXXX-XXXX-XXXX',
              prefixIcon: Icons.credit_card_rounded,
              animationIndex: 1,
            ),
          ],

          const SizedBox(height: 32),

          // Notifications
          Text(
            'Notifications',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          _SwitchTile(
            title: 'Notifications push',
            subtitle: 'Alertes sur vos trains et retards',
            icon: Icons.notifications_active_outlined,
            value: _notificationsActives,
            onChanged: (value) => setState(() => _notificationsActives = value),
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            title: 'Emails promotionnels',
            subtitle: 'Offres spéciales et réductions',
            icon: Icons.mail_outline_rounded,
            value: _emailsPromotionnels,
            onChanged: (value) => setState(() => _emailsPromotionnels = value),
          ),

          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vous pourrez modifier ces préférences à tout moment dans les paramètres de votre compte.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Icon(
              Icons.security_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Sécurisez votre compte',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez un mot de passe fort pour protéger votre compte',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // Password
          AnimatedTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            animationIndex: 1,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (value.length < 8) {
                return 'Minimum 8 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password strength
          _PasswordStrengthIndicator(password: _passwordController.text),
          const SizedBox(height: 24),

          // Confirm Password
          AnimatedTextField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            animationIndex: 2,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Password requirements
          _PasswordRequirements(password: _passwordController.text),
          const SizedBox(height: 32),

          // Terms
          _TermsCheckbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;
    final isFirstStep = _currentStep == 0;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            child: AnimatedButton(
              text: 'Retour',
              onPressed: _previousStep,
              isOutlined: true,
            ),
          ),
        if (!isFirstStep) const SizedBox(width: 16),
        Expanded(
          flex: isFirstStep ? 1 : 2,
          child: AnimatedButton(
            text: isLastStep ? 'Créer mon compte' : 'Continuer',
            onPressed: _nextStep,
            isLoading: _isLoading,
            icon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  String _getGenreLabel(Genre genre) {
    switch (genre) {
      case Genre.homme:
        return 'Homme';
      case Genre.femme:
        return 'Femme';
      case Genre.autre:
        return 'Autre';
      case Genre.nonSpecifie:
        return 'Non spécifié';
    }
  }

  String _getCarteLabel(CarteReduction carte) {
    switch (carte) {
      case CarteReduction.aucune:
        return 'Aucune';
      case CarteReduction.jeune:
        return 'Jeune (-26 ans)';
      case CarteReduction.senior:
        return 'Senior (+60 ans)';
      case CarteReduction.famille:
        return 'Famille';
      case CarteReduction.handicape:
        return 'Handicapé';
      case CarteReduction.militaire:
        return 'Militaire';
      case CarteReduction.etudiant:
        return 'Étudiant';
    }
  }

  IconData _getCarteIcon(CarteReduction carte) {
    switch (carte) {
      case CarteReduction.aucune:
        return Icons.cancel_outlined;
      case CarteReduction.jeune:
        return Icons.face_rounded;
      case CarteReduction.senior:
        return Icons.elderly_rounded;
      case CarteReduction.famille:
        return Icons.family_restroom_rounded;
      case CarteReduction.handicape:
        return Icons.accessible_rounded;
      case CarteReduction.militaire:
        return Icons.military_tech_rounded;
      case CarteReduction.etudiant:
        return Icons.school_rounded;
    }
  }
}

// ==================== HELPER WIDGETS ====================

class _AnimatedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedBackButton({required this.onPressed});

  @override
  State<_AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<_AnimatedBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        transform: _isPressed ? Matrix4.translationValues(0, 2, 0) : Matrix4.identity(),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isDark ? AppColors.grey300 : AppColors.grey700,
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.grey400,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (index < totalSteps - 1) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey400,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final DateTime dateNaissance;

  const _AgeBadge({required this.dateNaissance});

  int get age {
    final now = DateTime.now();
    int age = now.year - dateNaissance.year;
    if (now.month < dateNaissance.month ||
        (now.month == dateNaissance.month && now.day < dateNaissance.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$age ans',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  int get strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (password.length >= 12) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) s++;
    return s;
  }

  Color get color {
    if (strength <= 1) return AppColors.error;
    if (strength <= 2) return AppColors.warning;
    if (strength <= 3) return AppColors.warningLight;
    return AppColors.success;
  }

  String get label {
    if (strength <= 1) return 'Faible';
    if (strength <= 2) return 'Moyen';
    if (strength <= 3) return 'Bon';
    return 'Fort';
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < strength ? color : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Force: $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PasswordRequirements extends StatelessWidget {
  final String password;

  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exigences du mot de passe:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _RequirementRow(
          label: 'Au moins 8 caractères',
          isMet: password.length >= 8,
        ),
        _RequirementRow(
          label: 'Une lettre majuscule',
          isMet: RegExp(r'[A-Z]').hasMatch(password),
        ),
        _RequirementRow(
          label: 'Un chiffre',
          isMet: RegExp(r'[0-9]').hasMatch(password),
        ),
        _RequirementRow(
          label: 'Un caractère spécial (!@#\$%...)',
          isMet: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementRow({
    required this.label,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isMet ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: isMet ? AppColors.success : AppColors.grey400,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isMet
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isMet
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                  text: "J'accepte les ",
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                TextSpan(
                  text: "conditions d'utilisation",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' et la ',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                TextSpan(
                  text: 'politique de confidentialité',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' de SNTF.',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}