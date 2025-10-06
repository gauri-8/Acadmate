import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> handleGoogleLogin(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        hostedDomain: "iiitvadodara.ac.in",
      );

      // Clear any existing sign-in state
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      // Add a small delay to ensure sign-out is complete
      await Future.delayed(const Duration(milliseconds: 500));

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null && user.email!.endsWith("@iiitvadodara.ac.in")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome ${user.displayName}!")),
        );
      } else {
        await logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login with your IIITV email")),
        );
      }
    } catch (e,stack) {
      debugPrint("Google login error: $e");
      debugPrint("Stacktrace: $stack");
      
      // If there's an error, try to clear everything and show a helpful message
      await logout();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login failed. Please try again or restart the app.\nError: $e"),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Sign out from Google first
      await googleSignIn.signOut();
      
      // Then sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear any cached data
      await googleSignIn.disconnect();

      debugPrint("User logged out successfully.");
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AcadMate Login'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: Colors.blue[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to AcadMate',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Academic Management System',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => handleGoogleLogin(context),
                icon: const Icon(Icons.login),
                label: const Text("Continue with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Please use your IIITV email account',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
