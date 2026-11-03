import 'package:flutter/material.dart';

import 'common.dart';
import 'lobby_page.dart';

/// The loading screen between PLAY and the lobby. It only animates; nothing
/// is actually being downloaded.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key, required this.username});

  final String username;

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  static const _tips = [
    'Land near buildings to find weapons faster.',
    'Stay inside the safe zone as it shrinks.',
    'Team up with friends to survive longer.',
    'Listen for footsteps before you open a door.',
    'Loot first, fight second.',
  ];

  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));
    // Fast start, a pause in the middle, then a quick finish, like a real loader.
    _progress = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.30).chain(CurveTween(curve: Curves.easeOut)), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 0.30, end: 0.36), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 0.36, end: 0.82).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, __, ___) => LobbyPage(username: widget.username),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _stage(double value) {
    if (value < 0.3) return 'Connecting to server…';
    if (value < 0.6) return 'Loading resources…';
    if (value < 0.9) return 'Preparing the lobby…';
    return 'Almost ready…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        dim: 0.5,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, _) {
              final value = _progress.value;
              final tip = _tips[(value * _tips.length).floor().clamp(0, _tips.length - 1)];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    const GameTitle(size: 60),
                    const Spacer(),
                    Text(
                      'TIP: $tip',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 12,
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(kOrange),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${(value * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: kYellow),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_stage(value), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
