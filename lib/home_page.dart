import 'package:flutter/material.dart';

import 'common.dart';
import 'loading_page.dart';
import 'login_page.dart';

/// Shown right after login: the artwork, the title and the PLAY button.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.username});

  final String username;

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        dim: 0.2,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatar(name: username, size: 40, ring: kYellow),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const Text('Lv. 38', style: TextStyle(fontSize: 12, color: kYellow)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Log out',
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GameTitle(size: 64),
                        const SizedBox(height: 6),
                        Text(
                          'DROP IN. SURVIVE. WIN.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: Colors.white.withOpacity(0.9),
                            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: GameButton(
                    label: 'PLAY',
                    width: 220,
                    height: 64,
                    fontSize: 26,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => LoadingPage(username: username)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
