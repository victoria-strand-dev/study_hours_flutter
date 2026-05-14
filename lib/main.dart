import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/start_screen.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
  await StorageService.instance.init();
  await NotificationService.instance.init();

  final localData = StorageService.instance.loadAppData();
  final localEmail = StorageService.instance.userEmail;

  // Check if Firebase still has an active session
  final firebaseUser = FirebaseAuth.instance.currentUser;
  String? uid = firebaseUser?.uid;
  String? email = firebaseUser?.email ?? localEmail;

  AppData data = localData;
  if (uid != null) {
    try {
      final cloudData = await StorageService.instance.loadFromFirestore(uid);
      if (cloudData != null) data = cloudData;
    } catch (_) {
      // Cloud load failed — fall back to local cache
    }
  }

  final state = AppState(data, email, firebaseUid: uid);

  // Reschedule all notifications in case the OS cleared them (reboot, reinstall, etc.)
  NotificationService.instance.rescheduleAll(data.schedule);

  runApp(StudyHoursApp(state: state));
}

class StudyHoursApp extends StatelessWidget {
  final AppState state;
  const StudyHoursApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: state,
      child: MaterialApp(
        title: 'StudyHours',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const StartScreen(),
        builder: (context, child) => child!,
      ),
    );
  }
}
