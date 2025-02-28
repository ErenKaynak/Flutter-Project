import 'package:engineering_project/assets/components/auth_service.dart';
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
  //final _formKey = GlobalKey<FormState>();
  bool passToggle = true;
  /*bool emailVaild = RegExp(
    r"^[a-zA-Z0-9.a-zA-ZO-9.!#$%&'*+-/=?^_{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(emailController.text);*/

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
      //UserCredential credential = await _auth.signInWithEmailAndPassword();
      Navigator.pop(context);
      
      
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
                prefixIcon: Icon(Icons.email),
                suffix: null,
                validator: null, // need to FIX
              ),
              const SizedBox(height: 15),
              // password field
              signup(
                controller: passwordController,
                obscureText: passToggle,
                hintText: 'Password',
                prefixIcon: Icon(Icons.lock),
                suffix: InkWell(
                  onTap: () {
                    setState(() {
                      passToggle = !passToggle;
                    });
                  },
                  child: Icon(
                    passToggle ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                validator: null, //need to FIX
              ),

              const SizedBox(height: 9),

              // not a member ? register
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
              //forgot your password?
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

              //sign in button
              FloatingActionButton(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.grey[200],
                onPressed: () {
                  SignUserin();
                  //_formKey.currentState!.validate();
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
                      child: Divider(thickness: 1, color: Colors.grey[400]),
                    ),
                    Text('Or Log in With'),
                    Expanded(
                      child: Divider(thickness: 1, color: Colors.grey[400]),
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
                    onPressed: () => AuthService().signInWithGoogle(),
                  ),
                  const SizedBox(width: 20),

                  //apple button
                  SquareTile(
                    imagePath: 'lib/assets/Images/apple-logo.png',
                    onPressed: null, // FINISH APPLE SIGN IN
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
