import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/notifiers/auth.dart';
import 'package:flutterapp/navigator.dart';
import 'package:flutterapp/pages/home.dart';
import 'package:flutterapp/pages/prompt.dart';
import 'package:flutterapp/pages/sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthNotifier(),
      child: Consumer<AuthNotifier>(
        builder: (context, auth, child) {
          return MaterialApp(
            navigatorKey: MyNavigator.navigatorKey,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthDecider(),
              '/prompt': (context) => const PromptPage(),
            },
          );
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
