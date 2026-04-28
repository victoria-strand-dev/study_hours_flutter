import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Local data (SharedPreferences) is treated as a cache.
/// Firestore (single user document) is the source of truth for logged-in users.
///
/// NOTE: subcollections refactor is planned but requires updated Firebase
/// security rules to be deployed first. Until then the app uses the
/// single-document format: users/{uid}  →  { appData: { ... } }
class StorageService {
  static const _appDataKey       = 'app_data';
  static const _userEmailKey     = 'user_email';
  static const _onboardingKey    = 'onboarding_done';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService not initialized');
    return _prefs!;
  }

  // ─── Local cache (SharedPreferences) ──────────────────────────────────────

  AppData loadAppData() {
    final json = _p.getString(_appDataKey);
    if (json == null) return AppData();
    try {
      return AppData.fromJsonString(json);
    } catch (_) {
      return AppData();
    }
  }

  Future<void> saveAppData(AppData data) async {
    await _p.setString(_appDataKey, data.toJsonString());
  }

  String? get userEmail => _p.getString(_userEmailKey);

  Future<void> saveUserEmail(String email) async {
    await _p.setString(_userEmailKey, email);
  }

  Future<void> clearAll() async {
    await _p.clear();
  }

  bool get onboardingDone => _p.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingDone() async =>
      _p.setBool(_onboardingKey, true);

  // ─── Firestore ─────────────────────────────────────────────────────────────

  DocumentReference _userDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  /// Upload the full AppData to Firestore (single-document format).
  Future<void> saveToFirestore(String uid, AppData data) async {
    await _userDoc(uid).set({'appData': data.toJson()});
  }

  /// Download AppData from Firestore. Returns null if no document exists yet.
  Future<AppData?> loadFromFirestore(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    final raw = (doc.data() as Map<String, dynamic>?)?['appData'];
    if (raw == null) return null;
    try {
      return AppData.fromJson(raw as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Delete the user's Firestore document (and local cache).
  Future<void> deleteUserData(String uid) async {
    await _userDoc(uid).delete();
  }
}
