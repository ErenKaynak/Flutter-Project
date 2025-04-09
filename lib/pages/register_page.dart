import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engineering_project/assets/components/auth_service.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:engineering_project/pages/login_page.dart';
import 'package:engineering_project/pages/root_page.dart';

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
  final profileImageController = TextEditingController(); // optional

  bool passToggle = true;

  String? emailError;
  String? passwordError;

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

    if (passwordController.text.length < 6) {
      setState(() {
        passwordError = "Passwords must be 6 characters long";
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
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
                  Icon(Icons.lock, size: 100, color: Colors.red.shade700),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Sign in Here...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            fillColor: Colors.grey.shade300,
                            filled: true,
                            hintText: 'First Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter first name';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: surnameController,
                          decoration: InputDecoration(
                            fillColor: Colors.grey.shade300,
                            filled: true,
                            hintText: 'Last Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter last name';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Email Input
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade300,
                      filled: true,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Password Input
                  TextFormField(
                    controller: passwordController,
                    obscureText: passToggle,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade300,
                      filled: true,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passToggle ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(() => passToggle = !passToggle),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter a Password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Confirm Password Input
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: passToggle,
                    decoration: InputDecoration(
                      fillColor: Colors.grey.shade300,
                      filled: true,
                      hintText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          passToggle ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed:
                            () => setState(() => passToggle = !passToggle),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value != passwordController.text) {
                        return 'Enter a password';
                      }
                      return null;
                    },
                  ),
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
                        'You Have An Account?',
                        style: TextStyle(color: Colors.grey[800]),
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

                  // Register Button
                  FloatingActionButton(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.grey[200],
                    onPressed: signUserUp,
                    child: const Icon(Icons.arrow_forward, size: 25),
                  ),
                  const SizedBox(height: 25),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Or Log in With'),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Social Login
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
}
