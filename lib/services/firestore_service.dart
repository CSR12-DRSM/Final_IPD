import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    if (!AppConstants.useFirebase) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Save or update user profile document
  Future<void> saveUserProfile({required String email, String? displayName}) async {
    final db = _db;
    final uid = _uid;
    if (db == null || uid == null) return;

    await db.collection('users').doc(uid).set({
      'email': email,
      'displayName': displayName ?? '',
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Log an SOS Panic Alert to Firebase Firestore
  Future<void> logAlert({
    required String title,
    required String alertKind,
    required double latitude,
    required double longitude,
    required int heartRate,
  }) async {
    final db = _db;
    final uid = _uid;
    if (db == null || uid == null) return;

    await db.collection('users').doc(uid).collection('alerts').add({
      'title': title,
      'kind': alertKind,
      'latitude': latitude,
      'longitude': longitude,
      'heartRate': heartRate,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Log heart rate telemetry to Firebase Firestore
  Future<void> logHeartRate(int heartRate) async {
    final db = _db;
    final uid = _uid;
    if (db == null || uid == null) return;

    await db.collection('users').doc(uid).collection('heartRateLogs').add({
      'bpm': heartRate,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
