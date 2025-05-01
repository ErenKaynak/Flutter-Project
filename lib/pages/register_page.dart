import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'dart:math';

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

  void signInWithGoogleAndNavigate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await AuthService().signInWithGoogle();

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

    if (!hasMinLength || !hasMaxLength || !hasUpperCase || !hasLowerCase || !hasSpecialChar) {
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
        final referralDoc = await FirebaseFirestore.instance
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
            password: passwordController.text.trim(), // Fix: was using email as password
          );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        // Generate unique referral code for new user
        String referralCode = _generateReferralCode();
        
        // Create user document
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'profileImage': profileImageController.text.trim(),
          'role': 'user',
          'referralCode': referralCode,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Create referral code document
        await FirebaseFirestore.instance
            .collection('referral_codes')
            .doc(referralCode)
            .set({
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create wallet for new user with initial balance of 0
        await FirebaseFirestore.instance.collection('wallets').doc(uid).set({
          'balance': 0.0,
          'created_at': FieldValue.serverTimestamp(),
        });

        // If valid referral code was used, reward both users
        if (referrerUid != null) {
          // Add balance to referrer
          await FirebaseFirestore.instance.collection('wallets').doc(referrerUid).update({
            'balance': FieldValue.increment(100),
          });

          // Add balance to new user
          await FirebaseFirestore.instance.collection('wallets').doc(uid).update({
            'balance': FieldValue.increment(100),
          });

          // Record referral transaction for referrer
          await FirebaseFirestore.instance.collection('wallet_transactions').add({
            'user_id': referrerUid,
            'amount': 100,
            'type': 'referral_reward',  // Changed from 'referral_bonus'
            'description': 'Referral Reward', // Added description
            'referred_user': uid,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'method': 'referral',
          });

          // Record referral transaction for new user
          await FirebaseFirestore.instance.collection('wallet_transactions').add({
            'user_id': uid,
            'amount': 100,
            'type': 'referral_reward',  // Changed from 'signup_bonus'
            'description': 'Referral Reward', // Added description
            'referrer': referrerUid,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            'method': 'referral',
          });
        }
      }

      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
          (Route<dynamic> route) => false,
        );
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
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
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

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                              color: Colors.red.shade100,
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            isDark 
                              ? 'lib/assets/Images/app-icon-dark.png'
                              : 'lib/assets/Images/app-icon-light.png',
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Sign in Here...',
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
                          hintText: 'First Name',
                          icon: Icons.person,
                          validatorMsg: 'Enter first name',
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: surnameController,
                          hintText: 'Last Name',
                          icon: Icons.person,
                          validatorMsg: 'Enter last name',
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Email',
                    icon: Icons.email,
                    validatorMsg: 'Enter a email',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    controller: passwordController,
                    hintText: 'Password',
                    toggle: passToggle,
                    onToggle: () => setState(() => passToggle = !passToggle),
                    validatorMsg: 'Enter a Password',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    toggle: passToggle,
                    onToggle: () => setState(() => passToggle = !passToggle),
                    validatorMsg: 'Enter a password',
                    colorScheme: colorScheme,
                    isDark: isDark,
                    matchPassword: passwordController.text,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: referralCodeController,
                    hintText: 'Referral Code (Optional)',  // Note the "Optional" text
                    icon: Icons.card_giftcard,
                    validatorMsg: '',  // Empty validator message means no validation required
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  // Add password requirements here
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade700.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildPasswordRequirement('At least 8 characters', hasMinLength),
                        _buildPasswordRequirement('Maximum 20 characters', hasMaxLength),
                        _buildPasswordRequirement('One uppercase letter', hasUpperCase),
                        _buildPasswordRequirement('One lowercase letter', hasLowerCase),
                        _buildPasswordRequirement('One special character', hasSpecialChar),
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
                        style: const TextStyle(
                          color: Colors.red,
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
                        'You Have An Account?',
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
                          'Login!',
                          style: TextStyle(
                            color: Colors.red.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton(
                    backgroundColor: Colors.red.shade700,
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Or Log in With'),
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
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
      style: TextStyle(color: colorScheme.onBackground),
      validator: validatorMsg.isEmpty 
        ? null  // No validation for empty validatorMsg
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: toggle,
      onChanged: (value) {
        if (hintText == 'Password') {
          _checkPasswordRequirements(value);
        }
      },
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
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
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
          color: met ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 5),
        Text(
          requirement,
          style: TextStyle(
            fontSize: 12,
            color: met ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}
