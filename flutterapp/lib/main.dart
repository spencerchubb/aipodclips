import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutterapp/pages/sign_in.dart';
import 'package:flutterapp/pages/home.dart';
import 'package:provider/provider.dart';
import 'package:flutterapp/notifiers/auth.dart';

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
      child: MaterialApp(
        home: const PageDecider(),
      ),
    );
  }
}

class PageDecider extends StatelessWidget {
  const PageDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    return authNotifier.user != null ? const HomePage() : const SignInPage();
  }
}