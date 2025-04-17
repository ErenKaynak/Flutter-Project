import 'package:engineering_project/pages/register_page.dart';
import 'package:engineering_project/pages/root_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/forget_pw_page.dart';
import 'package:engineering_project/admin-panel/admin_root.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool passToggle = true;
  bool _mounted = true;
  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    _mounted = false;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signInWithGoogleAndNavigate() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await AuthService().signInWithGoogle();
      if (!_mounted) return;
      if (context.mounted) Navigator.pop(context);
      if (!_mounted) return;
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RootScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!_mounted) return;
      if (context.mounted) Navigator.pop(context);
      if (!_mounted) return;
      setState(() {
        emailError = "Google sign-in failed. Please try again.";
        print("Google Sign-In Error: $e");
      });
    }
  }

  void signUserIn() async {
    if (!mounted) return;
    setState(() {
      emailError = null;
      passwordError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      if (!_mounted) return;
      User? user = credential.user;
      if (user != null) {
        await _saveUserToFirestore(user);
        if (!_mounted) return;
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        String role = userDoc['role'] ?? 'user';
        if (!_mounted) return;
        if (context.mounted) Navigator.pop(context);
        if (!_mounted) return;
        if (context.mounted) {
          if (role == 'admin') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const RootScreen()),
              (Route<dynamic> route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const RootScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!_mounted) return;
      if (context.mounted) Navigator.pop(context);
      if (!_mounted) return;
      setState(() {
        switch (e.code) {
          case 'invalid-credential':
            emailError = "Email or Password is wrong please try again";
            break;
          case 'wrong-password':
            passwordError = "Incorrect password. Please try again.";
            break;
          case 'invalid-email':
            emailError = "The email address is badly formatted.";
            break;
          case 'user-disabled':
            emailError = "This user account has been disabled.";
            break;
          case 'too-many-requests':
            emailError =
                "Too many unsuccessful login attempts. Please try again later.";
            break;
          case 'missing-password':
            emailError = "Please Enter A Password.";
            break;
          default:
            emailError = "An error occurred. Please try again.";
            print("Firebase Auth Error: ${e.code}");
        }
      });
    } catch (e) {
      if (!_mounted) return;
      if (context.mounted) Navigator.pop(context);
      if (!_mounted) return;
      setState(() {
        emailError = "An unexpected error occurred. Please try again.";
        print("Unexpected Error: $e");
      });
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    if (!_mounted) return;
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final docSnapshot = await userDoc.get();
    if (!_mounted) return;
    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if device is in dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define colors based on theme
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.grey[200];
    final textColor = isDarkMode ? Colors.white : Colors.grey[700];
    final secondaryTextColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];
    final inputFillColor = isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[300];
    final dividerColor = isDarkMode ? Colors.grey[700] : Colors.grey[400];
    final iconColor = Colors.red.shade700;
    final accentColor = Colors.red.shade500;

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
                          color: isDarkMode ? Colors.grey[900] : Colors.white54,
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
                            isDarkMode 
                              ? 'lib/assets/Images/app-icon-dark.png'
                              : 'lib/assets/Images/app-icon-light.png',
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back! Log in Here',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      fillColor: inputFillColor,
                      filled: true,
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDarkMode ? Colors.grey[400] : null,
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
                        borderSide: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordController,
                    obscureText: passToggle,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      fillColor: inputFillColor,
                      filled: true,
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: isDarkMode ? Colors.grey[400] : null,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passToggle ? Icons.visibility : Icons.visibility_off,
                          color: isDarkMode ? Colors.grey[400] : null,
                        ),
                        onPressed:
                            () => setState(() => passToggle = !passToggle),
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
                        borderSide: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const SizedBox(height: 5),
                  if (emailError != null || passwordError != null)
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
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
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a member?',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Register!',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  FloatingActionButton(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    onPressed: signUserIn,
                    child: const Icon(Icons.arrow_forward, size: 25),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: dividerColor),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Or Log in With',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: dividerColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(
                        imagePath: 'lib/assets/Images/google-logo.png',
                        onPressed: () => signInWithGoogleAndNavigate(),
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
}
