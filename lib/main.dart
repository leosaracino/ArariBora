import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'src/screens/SignIn.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// TODO: Trocar o SHA-1 DEBUG para RELEASE https://developers.google.com/maps/documentation/android-sdk/get-api-key

/// Inicializa o serviço OneSignal.
Future initializeOneSignal() async {
  //Remove this method to stop OneSignal Debugging
  OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  OneSignal.shared.init("8554cdb2-23c2-4e34-a575-5596297b35f3");
  //OneSignal.shared.setInFocusDisplayType(OSNotificationDisplayType.notification);
  OneSignal.shared.setInFocusDisplayType(OSNotificationDisplayType.none);

  // The promptForPushNotificationsWithUserResponse function will show the iOS push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  await OneSignal.shared.promptUserForPushNotificationPermission(fallbackToSettings: true);
}

/// Ponto de entrada do programa.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeOneSignal();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { FocusScope.of(context).requestFocus(FocusNode()); },
      child: MaterialApp(
          theme: ThemeData(
              primaryColor: Color(0xFF3F9FFF),
              accentColor: Color(0xFFFF3F3F),
              scaffoldBackgroundColor: Color(0xFF1F1F1F),
              hintColor: Color(0xFF7F7F7F)
          ),
          title: 'Grupo 03 - Verde',
          home: SignInScreen()
      ),
    );
  }
}