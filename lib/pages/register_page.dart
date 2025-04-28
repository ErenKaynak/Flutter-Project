import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

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

  bool passToggle = true;

  String? emailError;
  String? passwordError;

  void signInWithGoogleAndNavigate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(
              color:
                  Provider.of<ThemeNotifier>(context).isBlackMode
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.red.shade700,
            ),
          ),
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

    if (passwordController.text.length < 8) {
      setState(() {
        passwordError = "Passwords must be 8 characters long";
      });
      return;
    } else if (passwordController.text.length > 20) {
      setState(() {
        passwordError = "Passwords must be less than 20 characters long";
      });
      return;
    }

    if (!passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      setState(() {
        passwordError = "Password must contain at least one special character";
      });
      return;
    }

    if (!passwordController.text.contains(RegExp(r'[A-Z]'))) {
      setState(() {
        passwordError = "Password must contain at least one uppercase letter";
      });
      return;
    }

    if (!passwordController.text.contains(RegExp(r'[a-z]'))) {
      setState(() {
        passwordError = "Password must contain at least one lowercase letter";
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(
              color:
                  Provider.of<ThemeNotifier>(context).isBlackMode
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.red.shade700,
            ),
          ),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': emailController.text.trim(),
          'name': nameController.text.trim(),
          'surname': surnameController.text.trim(),
          'profileImage': profileImageController.text.trim(),
          'role': 'user',
          'created_at': FieldValue.serverTimestamp(),
        });
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    profileImageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlackMode = themeNotifier.isBlackMode;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
    final accentColor =
        isBlackMode
            ? Theme.of(context).colorScheme.secondary
            : Colors.red.shade500;
    final iconColor =
        isBlackMode
            ? Theme.of(context).colorScheme.secondary
            : Colors.red.shade700;

    return Scaffold(
      backgroundColor: bgColor,
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
                              isBlackMode
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.3)
                                  : Colors.red.shade100,
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
                      color: textColor,
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
                          iconColor: iconColor,
                          borderColor: borderColor,
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
                          iconColor: iconColor,
                          borderColor: borderColor,
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
                    iconColor: iconColor,
                    borderColor: borderColor,
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
                    iconColor: iconColor,
                    borderColor: borderColor,
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
                    iconColor: iconColor,
                    borderColor: borderColor,
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
                              isBlackMode
                                  ? Theme.of(context).colorScheme.secondary
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
                        'You Have An Account?',
                        style: TextStyle(color: textColor),
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
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton(
                    backgroundColor: iconColor,
                    foregroundColor: colorScheme.onPrimary,
                    onPressed: signUserUp,
                    child: const Icon(Icons.arrow_forward, size: 25),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1, color: borderColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Or Log in With',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: borderColor),
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
    required Color iconColor,
    required Color borderColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(
          icon,
          color: isDark ? colorScheme.onSurface : iconColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      style: TextStyle(color: colorScheme.onBackground),
      validator: (value) {
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
    required Color iconColor,
    required Color borderColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: toggle,
      decoration: InputDecoration(
        fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
        filled: true,
        hintText: hintText,
        hintStyle: TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(
          Icons.lock,
          color: isDark ? colorScheme.onSurface : iconColor,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            toggle ? Icons.visibility : Icons.visibility_off,
            color: isDark ? colorScheme.onSurface : iconColor,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: iconColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
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
}
