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

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return const Stream.empty();
    return auth.authStateChanges();
  }

  Future<void> login(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is disabled or not initialized.');
    }
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user?.email != null) {
        try {
          await FirestoreService().saveUserProfile(email: cred.user!.email!);
        } catch (_) {
          // Ignore secondary firestore errors on auth login
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthException(e));
    }
  }

  Future<void> signUp(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is disabled or not initialized.');
    }
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (cred.user?.email != null) {
        try {
          await FirestoreService().saveUserProfile(email: cred.user!.email!);
        } catch (_) {
          // Ignore secondary firestore errors on auth signup
        }
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthException(e));
    }
  }

  Future<void> resetPassword(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is disabled or not initialized.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_parseAuthException(e));
    }
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) return;
    await auth.signOut();
  }

  String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

