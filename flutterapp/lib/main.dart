import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/navigator.dart';
import 'package:flutterapp/notifiers/auth.dart';
import 'package:flutterapp/notifiers/video.dart';
import 'package:flutterapp/pages/home.dart';
import 'package:flutterapp/pages/sign_in.dart';
import 'package:flutterapp/pages/video.dart';
import 'package:flutterapp/pages/transcript.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthNotifier()),
        ChangeNotifierProvider(create: (context) => VideoNotifier()),
      ],
      child: MaterialApp(
        navigatorKey: MyNavigator.navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthDecider(),
          '/video': (context) => const VideoPage(),
          '/transcript': (context) => const TranscriptPage(),
        },
      ),
    );
  }
}

class AuthDecider extends StatelessWidget {
  const AuthDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    return authNotifier.user == null ? const SignInPage() : const HomePage();
  }
}
