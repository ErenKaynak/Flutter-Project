import 'package:engineering_project/assets/components/buttons.dart';
import 'package:engineering_project/assets/components/square_tile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Text Editing Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void SignUserin() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      //geçici işaretler

      //WRONG MAIL
      if (e.code == 'user-not-found') {
        //show error to user—
        
      }
      //WRONG PASSWORD
      else if (e.code == 'wrong-password') {
        //show error to user
        
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        // safearea make avoid the devices notch part on the screen
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 110),
              // logo
              Icon(Icons.lock, size: 100, color: Colors.red.shade700),

              const SizedBox(height: 20),

              // welcome text
              Text(
                'Welcome Back! You can Log in Here',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              // email field
              signup(
                controller: emailController,
                obscureText: false,
                hintText: 'Email',
              ),
              const SizedBox(height: 15),
              // password field
              signup(
                controller: passwordController,
                obscureText: true,
                hintText: 'Password',
              ),

              const SizedBox(height: 9),

              // forget password field
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You Are Not a Member?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 4),
                  Text('Register!', style: TextStyle(color: Colors.blue)),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Forgot your password?',
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // sign in button
              FloatingActionButton(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.grey[200],
                onPressed: () {
                  SignUserin();
                },
                child: Icon(Icons.arrow_forward, size: 25),
              ),

              const SizedBox(height: 25),

              //or continue with
              Padding(
                padding: const EdgeInsets.fromLTRB(90, 0, 90, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text('Or Log in With'),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              // google + apple buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //google button
                  SquareTile(
                    imagePath: 'lib/assets/Images/google-logo.png',
                  ),

                  const SizedBox(width: 20),

                  SquareTile(
                    imagePath: 'lib/assets/Images/apple-logo.png',
                  ),
                ],
              ),

              // not a member ? register
            ],
          ),
        ),
      ),
    );
  }

}