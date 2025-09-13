import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> handleGoogleLogin(BuildContext context) async {
    try {
      // Step 1: Trigger Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        // Restrict login to only your institute domain
        hostedDomain: "iiitv.ac.in",
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // cancelled login

      // Step 2: Get Auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Step 3: Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign in to Firebase
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      // Step 5: Verify email domain
      if (user != null && user.email!.endsWith("@iiitvadodara.ac.in")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Welcome ${user.displayName}!")),
        );
        // Navigate to next page (role based navigation later)
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login with your IIITV email")),
        );
      }
    } catch (e) {
      debugPrint("Google login error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed, try again")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => handleGoogleLogin(context),
          icon: const Icon(Icons.login),
          label: const Text("Continue with Google"),
        ),
      ),
    );
  }
}
