import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _handleSignIn(account);
      }
    });
    googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn(GoogleSignInAccount account) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignInAuthentication googleSignInAuthentication = await account.authentication;
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(authCredential);
      final User? user = userCredential.user;

      if (user != null) {
        if (user.email == 'mswhd121@gmail.com') {
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool('isLoggedIn', true);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          await FirebaseAuth.instance.signOut();
          await googleSignIn.signOut();
          _showErrorDialog('Access Denied', 'You are not authorized to use this app.');
        }
      }
    } catch (error) {
      _showErrorDialog('Error', 'An error occurred during Google sign-in: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: () async {
            try {
              await googleSignIn.signIn();
            } catch (error) {
              _showErrorDialog('Error', 'An error occurred during Google sign-in: $error');
            }
          },
          child: const Text("Continue with Google"),
        ),
      ),
    );
  }
}
