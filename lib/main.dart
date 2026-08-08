import 'package:flutter/material.dart';
import 'services/forum_service.dart';
import 'screens/auth_screen.dart';
import 'screens/discussions_list_screen.dart';

const kPrimary = Color(0xFF4D698E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await ForumService().loadSession();
  runApp(SuckitApp(initiallyLoggedIn: loggedIn));
}

class SuckitApp extends StatelessWidget {
  final bool initiallyLoggedIn;
  const SuckitApp({super.key, required this.initiallyLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suckit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimary,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
      ),
      home: initiallyLoggedIn ? const DiscussionsListScreen() : const AuthScreen(),
    );
  }
}
