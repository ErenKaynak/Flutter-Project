import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'package:engineering_project/l10n/app_localizations.dart';
import 'package:engineering_project/assets/components/email_service.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final profileImageController = TextEditingController();
  final referralCodeController = TextEditingController();

  bool passToggle = true;

  String? emailError;
  String? passwordError;

  bool hasUpperCase = false;
  bool hasLowerCase = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  bool hasMaxLength = true;

  String getLogoAssetForTheme(ThemeNotifier themeNotifier, bool isDarkMode) {
    if (themeNotifier.isSpecialModeActive) {
      switch (themeNotifier.specialTheme) {
        case SpecialTheme.blue:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-blue.png'
              : 'lib/assets/Images/app-icon-light-blue.png';
        case SpecialTheme.yellow:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-yellow.png'
              : 'lib/assets/Images/app-icon-light-yellow.png';
        case SpecialTheme.green:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-green.png'
              : 'lib/assets/Images/app-icon-light-green.png';
        case SpecialTheme.orange:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-orange.png'
              : 'lib/assets/Images/app-icon-light-orange.png';
        case SpecialTheme.purple:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark-purple.png'
              : 'lib/assets/Images/app-icon-light-purple.png';
        default:
          return isDarkMode
              ? 'lib/assets/Images/app-icon-dark.png'
              : 'lib/assets/Images/app-icon-light.png';
      }
    } else {
      return isDarkMode
          ? 'lib/assets/Images/app-icon-dark.png'
          : 'lib/assets/Images/app-icon-light.png';
    }
  }

  void signInWithGoogleAndNavigate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService().signInWithGoogle(context);

      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      setState(() {
        emailError = "Google sign-in failed. Please try again.";
        print("Google Sign-In Error: $e");
      });
    }
  }

  void signUserUp() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        passwordError = "Passwords do not match";
      });
      return;
    }

    if (!hasMinLength ||
        !hasMaxLength ||
        !hasUpperCase ||
        !hasLowerCase ||
        !hasSpecialChar) {
      setState(() {
        passwordError = "Please meet all password requirements";
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Check if referral code exists only if one was provided
      String? referrerUid;
      if (referralCodeController.text.isNotEmpty) {
        final referralDoc =
            await FirebaseFirestore.instance
                .collection('referral_codes')
                .doc(referralCodeController.text.trim())
                .get();

        if (referralDoc.exists) {
          referrerUid = referralDoc.data()?['userId'];
        }
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Generate unique referral code for new user
        String referralCode = _generateReferralCode();

        // Create user document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': emailController.text.trim().toLowerCase(),
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'profileImageUrl': profileImageController.text.trim(),
          'role': 'user',
          'referral_code': referralCode,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });

        // Create wallet for new user
        await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user.uid)
            .set({
          'balance': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });

        // If referral code was used, update referrer's document
        if (referrerUid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(referrerUid)
              .update({
            'referrals': FieldValue.arrayUnion([user.uid])
          });
        }

        if (context.mounted) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Email Verification"),
              content: Text("A verification email has been sent to your email address. Please verify your email before logging in."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          preFilledEmail: emailController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);

      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            emailError = "Account already exists";
            break;
          case 'invalid-email':
            emailError = "Bad formatted email";
            break;
          case 'weak-password':
            passwordError = "Passwords must be 6 characters long";
            break;
          default:
            emailError = "An error occurred. Please try again.";
            print("Firebase Auth Error: ${e.code}");
        }
      });
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      setState(() {
        emailError = "An unexpected error occurred. Please try again.";
        print("Unexpected Error: $e");
      });
    }
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _checkPasswordRequirements(String password) {
    setState(() {
      hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      hasLowerCase = password.contains(RegExp(r'[a-z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
      hasMaxLength = password.length <= 20;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final l10n = AppLocalizations.of(context)!;

    // Consistent background color logic
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[200];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white54,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              themeNotifier.isSpecialModeActive
                                  ? themeNotifier
                                      .getThemeColor(themeNotifier.specialTheme)
                                      .shade100
                                  : Colors.red.shade100,
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        getLogoAssetForTheme(themeNotifier, isDark),
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.welcome,
                    style: TextStyle(
                      color: colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: nameController,
                          hintText: l10n.firstName,
                          icon: Icons.person,
                          validatorMsg: l10n.pleaseEnterFirstName,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: surnameController,
                          hintText: l10n.lastName,
                          icon: Icons.person,
                          validatorMsg: l10n.pleaseEnterLastName,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: emailController,
                    hintText: l10n.email,
                    icon: Icons.email,
                    validatorMsg: 'Please enter your email',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    controller: passwordController,
                    hintText: l10n.password,
                    toggle: passToggle,
                    onToggle: () => setState(() => passToggle = !passToggle),
                    validatorMsg: l10n.password,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    onChanged: (value) => _checkPasswordRequirements(value),
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    hintText: l10n.confirmPassword,
                    toggle: passToggle,
                    onToggle: () => setState(() => passToggle = !passToggle),
                    validatorMsg: l10n.confirmPassword,
                    colorScheme: colorScheme,
                    isDark: isDark,
                    matchPassword: passwordController.text,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: referralCodeController,
                    hintText: l10n.referralCode + ' (Optional)',
                    icon: Icons.card_giftcard,
                    validatorMsg: '',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            themeNotifier.isSpecialModeActive
                                ? themeNotifier
                                    .getThemeColor(themeNotifier.specialTheme)
                                    .shade700
                                    .withOpacity(0.3)
                                : Colors.red.shade700.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.passwordRequirements,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildPasswordRequirement(
                          l10n.maximum20Characters,
                          hasMaxLength,
                        ),
                        _buildPasswordRequirement(
                          l10n.atLeast8Characters,
                          hasMinLength,
                        ),
                        _buildPasswordRequirement(
                          l10n.oneUppercaseLetter,
                          hasUpperCase,
                        ),
                        _buildPasswordRequirement(
                          l10n.oneLowercaseLetter,
                          hasLowerCase,
                        ),
                        _buildPasswordRequirement(
                          l10n.oneSpecialCharacter,
                          hasSpecialChar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (emailError != null || passwordError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        emailError ?? passwordError ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              themeNotifier.isSpecialModeActive
                                  ? themeNotifier.getThemeColor(
                                    themeNotifier.specialTheme,
                                  )
                                  : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: TextStyle(color: colorScheme.onBackground),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.login + '!',
                          style: TextStyle(
                            color:
                                themeNotifier.isSpecialModeActive
                                    ? themeNotifier
                                        .getThemeColor(
                                          themeNotifier.specialTheme,
                                        )
                                        .shade500
                                    : Colors.red.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton(
                    backgroundColor:
                        themeNotifier.isSpecialModeActive
                            ? themeNotifier
                                .getThemeColor(themeNotifier.specialTheme)
                                .shade700
                            : Colors.red.shade700,
                    foregroundColor: colorScheme.onPrimary,
                    onPressed: signUserUp,
                    child: const Icon(Icons.arrow_forward, size: 25),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.orLogInWith ?? 'Or Log in With',
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        imagePath: 'lib/assets/Images/google-logo.png',
                        onPressed: signInWithGoogleAndNavigate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String validatorMsg,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(icon, color: colorScheme.onSurface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context)
                        .getThemeColor(
                          Provider.of<ThemeNotifier>(context).specialTheme,
                        )
                        .shade700
                    : Colors.red.shade700,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context)
                        .getThemeColor(
                          Provider.of<ThemeNotifier>(context).specialTheme,
                        )
                        .shade700
                    : Colors.red.shade700,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(color: colorScheme.onBackground),
      validator:
          validatorMsg.isEmpty
              ? null
              : (value) {
                if (value == null || value.isEmpty) return validatorMsg;
                return null;
              },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool toggle,
    required VoidCallback onToggle,
    required String validatorMsg,
    required ColorScheme colorScheme,
    required bool isDark,
    String? matchPassword,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: toggle,
      onChanged: onChanged,
      decoration: InputDecoration(
        fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface),
        suffixIcon: IconButton(
          icon: Icon(toggle ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context)
                        .getThemeColor(
                          Provider.of<ThemeNotifier>(context).specialTheme,
                        )
                        .shade700
                    : Colors.red.shade700,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Provider.of<ThemeNotifier>(context).isSpecialModeActive
                    ? Provider.of<ThemeNotifier>(context)
                        .getThemeColor(
                          Provider.of<ThemeNotifier>(context).specialTheme,
                        )
                        .shade700
                    : Colors.red.shade700,
            width: 2,
          ),
        ),
      ),
      style: TextStyle(color: colorScheme.onBackground),
      validator: (value) {
        if (value == null || value.isEmpty) return validatorMsg;
        if (matchPassword != null && value != matchPassword) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordRequirement(String requirement, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.cancel,
          color: met ? Colors.green : Colors.red, // Always use green/red
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          requirement,
          style: TextStyle(
            fontSize: 12,
            color: met ? Colors.green : Colors.red, // Always use green/red
          ),
        ),
      ],
    );
  }
}
