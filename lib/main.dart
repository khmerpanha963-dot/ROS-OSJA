import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole app is landscape, like a mobile game.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const RosOsjaApp());
}

class RosOsjaApp extends StatelessWidget {
  const RosOsjaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROS OSJA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A00),
          brightness: Brightness.dark,
        ),
      ),
      // Always starts on the login screen.
      home: const LoginPage(),
    );
  }
}
