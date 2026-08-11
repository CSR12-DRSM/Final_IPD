import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth? _auth =
      AppConstants.useFirebase ? FirebaseAuth.instance : null;

  Future<void> login(String email, String password) async {
    if (!AppConstants.useFirebase) return;
    await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String email, String password) async {
    if (!AppConstants.useFirebase) return;
    await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    if (!AppConstants.useFirebase) return;
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    if (!AppConstants.useFirebase) return;
    await _auth!.signOut();
  }
}
