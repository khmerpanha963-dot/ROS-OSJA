import 'package:flutter/material.dart';

import 'common.dart';
import 'login_page.dart';

enum PlayerStatus { online, inMatch, away }

class Player {
  const Player(this.name, this.level, this.status);
  final String name;
  final int level;
  final PlayerStatus status;
}

// Made-up players, just to fill the scrolling list.
const _players = <Player>[
  Player('NightFox', 52, PlayerStatus.online),
  Player('SokhaKH', 41, PlayerStatus.inMatch),
  Player('DragonEye', 67, PlayerStatus.online),
  Player('AngkorWolf', 33, PlayerStatus.away),
  Player('ViperX', 58, PlayerStatus.online),
  Player('LunaStar', 29, PlayerStatus.inMatch),
  Player('RedFalcon', 74, PlayerStatus.online),
  Player('KhmerTiger', 46, PlayerStatus.online),
  Player('BlazeKing', 61, PlayerStatus.away),
  Player('ShadowCat', 38, PlayerStatus.inMatch),
  Player('MekongRay', 49, PlayerStatus.online),
  Player('IronPanda', 55, PlayerStatus.online),
  Player('ZeroHero', 23, PlayerStatus.away),
  Player('StormRider', 70, PlayerStatus.inMatch),
  Player('CobraSnap', 44, PlayerStatus.online),
  Player('PixelWitch', 36, PlayerStatus.online),
  Player('TurboNeak', 63, PlayerStatus.away),
  Player('GhostMelon', 27, PlayerStatus.online),
  Player('SilverArrow', 80, PlayerStatus.inMatch),
  Player('LotusBlade', 51, PlayerStatus.online),
  Player('CrimsonOwl', 42, PlayerStatus.online),
  Player('BambooSky', 35, PlayerStatus.away),
  Player('RockyRoad', 59, PlayerStatus.online),
  Player('FrostByte', 66, PlayerStatus.inMatch),
  Player('HoneyBadger', 48, PlayerStatus.online),
  Player('TempleRun', 31, PlayerStatus.online),
  Player('JungleJet', 72, PlayerStatus.away),
  Player('SunsetKid', 25, PlayerStatus.online),
  Player('OceanDrift', 57, PlayerStatus.online),
  Player('EchoWolf', 64, PlayerStatus.inMatch),
];

enum GameMode { solo, duo, squad }

extension GameModeInfo on GameMode {
  String get label => switch (this) {
        GameMode.solo => 'SOLO',
        GameMode.duo => 'DUO',
        GameMode.squad => 'SQUAD',
      };

  int get teamSize => switch (this) {
        GameMode.solo => 1,
        GameMode.duo => 2,
        GameMode.squad => 4,
      };
}

Color _statusColor(PlayerStatus status) => switch (status) {
      PlayerStatus.online => const Color(0xFF3DDC84),
      PlayerStatus.inMatch => kOrange,
      PlayerStatus.away => Colors.grey,
    };

String _statusText(PlayerStatus status) => switch (status) {
      PlayerStatus.online => 'Online',
      PlayerStatus.inMatch => 'In match',
      PlayerStatus.away => 'Away',
    };

/// The lobby. Looks like a game lobby but you cannot actually play.
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key, required this.username});

  final String username;

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  GameMode _mode = GameMode.squad;
  final List<Player> _team = []; // teammates (not counting you)

  int get _slots => _mode.teamSize;

  void _setMode(GameMode mode) {
    setState(() {
      _mode = mode;
      final room = mode.teamSize - 1;
      if (_team.length > room) _team.removeRange(room, _team.length);
    });
  }

  void _toggleInvite(Player player) {
    setState(() {
      if (_team.contains(player)) {
        _team.remove(player);
      } else if (_team.length < _slots - 1) {
        _team.add(player);
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 1),
            content: Text('Your ${_mode.label.toLowerCase()} team is full.'),
          ));
      }
    });
  }

  Future<void> _start() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview only'),
        content: const Text('ROS OSJA is a lobby preview. Matches are not available.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _exit() async {
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
    if (ok == true && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        dim: 0.55,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 250, child: _playerList()),
                      const SizedBox(width: 12),
                      Expanded(child: _stage()),
                      const SizedBox(width: 12),
                      SizedBox(width: 210, child: _modePanel()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          PlayerAvatar(name: widget.username, size: 42, ring: kYellow),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 3),
              SizedBox(
                width: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(kYellow),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text('Lv. 38', style: TextStyle(color: kYellow, fontWeight: FontWeight.w700)),
          const Spacer(),
          const Chip2(icon: Icons.monetization_on, text: '12,450'),
          const SizedBox(width: 8),
          const Chip2(icon: Icons.diamond, text: '320', color: Color(0xFF5CD6FF)),
          const SizedBox(width: 8),
          IconButton(tooltip: 'Log out', onPressed: _exit, icon: const Icon(Icons.logout)),
        ],
      ),
    );
  }

  /// Left: the scrolling list of players with their avatars.
  Widget _playerList() {
    final online = _players.where((p) => p.status != PlayerStatus.away).length;
    return Container(
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.groups, size: 18, color: kOrange),
                const SizedBox(width: 8),
                const Text('PLAYERS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const Spacer(),
                Text('$online online', style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _players.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 66, color: Colors.white10),
              itemBuilder: (context, index) {
                final player = _players[index];
                final invited = _team.contains(player);
                return ListTile(
                  dense: true,
                  selected: invited,
                  selectedTileColor: kOrange.withOpacity(0.16),
                  onTap: () => _toggleInvite(player),
                  leading: PlayerAvatar(name: player.name, size: 40, ring: _statusColor(player.status)),
                  title: Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Lv. ${player.level} · ${_statusText(player.status)}',
                      style: TextStyle(fontSize: 11, color: _statusColor(player.status))),
                  trailing: Icon(invited ? Icons.check_circle : Icons.person_add_alt,
                      size: 20, color: invited ? kYellow : Colors.white54),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Middle: your character on a platform with the team slots underneath.
  Widget _stage() {
    return Column(
      children: [
        const Spacer(),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [kOrange.withOpacity(0.55), Colors.transparent]),
              ),
            ),
            PlayerAvatar(name: widget.username, size: 112, ring: kYellow),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.username,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slots; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              _slot(i),
            ],
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _slot(int index) {
    if (index == 0) {
      return Column(
        children: [
          PlayerAvatar(name: widget.username, size: 54, ring: kYellow),
          const SizedBox(height: 4),
          const Text('You', style: TextStyle(fontSize: 11, color: kYellow)),
        ],
      );
    }
    final teammate = index - 1 < _team.length ? _team[index - 1] : null;
    if (teammate == null) {
      return Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
            child: const Icon(Icons.add, color: Colors.white54),
          ),
          const SizedBox(height: 4),
          const Text('Invite', style: TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _toggleInvite(teammate),
      child: Column(
        children: [
          PlayerAvatar(name: teammate.name, size: 54, ring: _statusColor(teammate.status)),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(teammate.name,
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  /// Right: choose the mode and press START.
  Widget _modePanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('MODE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          for (final mode in GameMode.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _setMode(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _mode == mode ? kOrange.withOpacity(0.25) : Colors.white10,
                    border: Border.all(color: _mode == mode ? kOrange : Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${mode.teamSize}P', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          GameButton(label: 'START', onPressed: _start, height: 56, fontSize: 22),
        ],
      ),
    );
  }
}
