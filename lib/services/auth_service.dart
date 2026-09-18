import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import 'firestore_service.dart';

class AuthService {
  FirebaseAuth? get _auth {
    if (!AppConstants.useFirebase) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;

  Future<void> login(String email, String password) async {
    final auth = _auth;
    if (auth == null) return;
    final cred = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user?.email != null) {
      await FirestoreService().saveUserProfile(email: cred.user!.email!);
    }
  }

  Future<void> signUp(String email, String password) async {
    final auth = _auth;
    if (auth == null) return;
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user?.email != null) {
      await FirestoreService().saveUserProfile(email: cred.user!.email!);
    }
  }

  Future<void> resetPassword(String email) async {
    final auth = _auth;
    if (auth == null) return;
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
  }
}
