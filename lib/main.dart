import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/login_page.dart';
import 'services/auth_service.dart';
import 'widgets/badge_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  runApp(const SmartSafetyBadgeApp());
}

class SmartSafetyBadgeApp extends StatelessWidget {
  const SmartSafetyBadgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _Entry(),
    );
  }
}

class _Entry extends StatefulWidget {
  const _Entry();

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginPage(onLogin: () {});
        }
        return GuardianShell(
          onLogout: () async {
            await _authService.logout();
          },
        );
      },
    );
  }
}


class GuardianAlert {
  GuardianAlert({
    required this.title,
    required this.time,
    required this.kind,
    required this.icon,
    required this.iconBg,
    this.subtitle,
    this.isNew = false,
  });

  final String title;
  final String time;
  final String kind;
  final IconData icon;
  final Color iconBg;
  final String? subtitle;
  bool isNew;
  bool expanded = false;
}

class GuardianShell extends StatefulWidget {
  const GuardianShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<GuardianShell> createState() => _GuardianShellState();
}

class _GuardianShellState extends State<GuardianShell> {
  int tab = 0;
  int heartRate = 82;
  bool deviceConnected = true;
  int battery = 84;
  bool locationActive = true;
  bool safeArea = true;
  bool alertSound = true;
  bool alertSms = true;
  Timer? sosTimer;
  Timer? recordingTimer;
  bool holdingSos = false;
  bool playingRecording = false;
  double recordingProgress = 0;

  final List<GuardianAlert> alerts = [
    GuardianAlert(
      title: 'You pressed the SOS button',
      time: 'Today at 9:14 AM',
      kind: 'SOS',
      icon: Icons.sos_rounded,
      iconBg: const Color(0xFFFFE8EF),
      isNew: true,
      subtitle:
          'An emergency alert was sent to your guardians. Your location was shared and a recording was saved.',
    ),
    GuardianAlert(
      title: 'You left your safe area',
      time: 'Yesterday at 6:30 PM',
      kind: 'SAFE AREA',
      icon: Icons.location_on_rounded,
      iconBg: const Color(0xFFEDEBFF),
      subtitle:
          'Your device detected that you moved outside your home safe zone.',
    ),
    GuardianAlert(
      title: 'You pressed the SOS button',
      time: 'Aug 9 at 11:08 AM',
      kind: 'SOS',
      icon: Icons.sos_rounded,
      iconBg: const Color(0xFFFFE8EF),
      subtitle: 'Emergency alert completed successfully.',
    ),
    GuardianAlert(
      title: 'Battery was very low (8%)',
      time: 'Aug 8 at 4:22 PM',
      kind: 'BATTERY',
      icon: Icons.battery_alert_rounded,
      iconBg: const Color(0xFFFFF2DF),
      subtitle: 'The badge battery dropped below the warning level.',
    ),
    GuardianAlert(
      title: 'You left your safe area',
      time: 'Aug 7 at 2:10 PM',
      kind: 'SAFE AREA',
      icon: Icons.location_on_rounded,
      iconBg: const Color(0xFFEDEBFF),
      subtitle: 'The badge was outside the configured safe area.',
    ),
  ];

  List<GuardianAlert> get newAlerts => alerts.where((a) => a.isNew).toList();

  void addSosAlert() {
    setState(() {
      for (final alert in alerts) {
        alert.isNew = false;
      }
      alerts.insert(
        0,
        GuardianAlert(
          title: 'You pressed the SOS button',
          time: 'Just now',
          kind: 'SOS',
          icon: Icons.sos_rounded,
          iconBg: const Color(0xFFFFE8EF),
          isNew: true,
          subtitle:
              'Emergency alert sent to your guardians. Location shared successfully.',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS alert sent to all active guardians.')),
    );
  }

  void addHeartRateAlert() {
    setState(() {
      for (final alert in alerts) {
        alert.isNew = false;
      }
      alerts.insert(
        0,
        GuardianAlert(
          title: 'Abnormal heart rate detected',
          time: 'Just now',
          kind: 'HEART RATE',
          icon: Icons.favorite_rounded,
          iconBg: const Color(0xFFFFE8EF),
          isNew: true,
          subtitle:
              'Heart rate reached $heartRate BPM, meeting the configured ${AppConstants.heartRateThreshold} BPM alert threshold.',
        ),
      );
    });
  }

  void setHeartRate(int bpm) {
    setState(() => heartRate = bpm);
    if (bpm >= AppConstants.heartRateThreshold) {
      addHeartRateAlert();
    }
  }

  void startSosHold() {
    if (holdingSos) return;
    setState(() => holdingSos = true);
    sosTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => holdingSos = false);
      addSosAlert();
    });
  }

  void cancelSosHold() {
    if (sosTimer?.isActive ?? false) sosTimer!.cancel();
    if (mounted && holdingSos) setState(() => holdingSos = false);
  }

  void toggleRecording() {
    if (playingRecording) {
      recordingTimer?.cancel();
      setState(() => playingRecording = false);
      return;
    }
    setState(() {
      playingRecording = true;
      recordingProgress = 0;
    });
    recordingTimer?.cancel();
    recordingTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      setState(() {
        recordingProgress += .018;
        if (recordingProgress >= 1) {
          recordingProgress = 0;
          playingRecording = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    sosTimer?.cancel();
    recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width =
                constraints.maxWidth < 540 ? constraints.maxWidth : 540.0;
            return Center(
              child: Container(
                width: width,
                color: AppTheme.pageBg,
                child: Column(
                  children: [
                    Expanded(child: _page()),
                    _BottomNav(
                      current: tab,
                      alertCount: newAlerts.length,
                      onChanged: (value) => setState(() => tab = value),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _page() {
    switch (tab) {
      case 0:
        return HomeView(
          battery: battery,
          locationActive: locationActive,
          alertsToday: 2 + alerts.where((a) => a.time == 'Just now').length,
          guardiansWatching: 2,
          safeArea: safeArea,
          holdingSos: holdingSos,
          onSosStart: startSosHold,
          onSosCancel: cancelSosHold,
          onAlerts: () => setState(() => tab = 2),
        );
      case 1:
        return HealthView(
          heartRate: heartRate,
          battery: battery,
          connected: deviceConnected,
          onToggleConnection: () =>
              setState(() => deviceConnected = !deviceConnected),
          onHeartRate: setHeartRate,
          onBack: () => setState(() => tab = 0),
        );
      case 2:
        return AlertsView(
          alerts: alerts,
          onBack: () => setState(() => tab = 0),
          onMarkRead: (alert) => setState(() => alert.isNew = false),
        );
      case 3:
        return RecordingsView(
          playing: playingRecording,
          progress: recordingProgress,
          onTogglePlay: toggleRecording,
        );
      case 4:
        return ProfileView(
          battery: battery,
          connected: deviceConnected,
          safeArea: safeArea,
          alertSound: alertSound,
          alertSms: alertSms,
          onSafeAreaChanged: (value) => setState(() => safeArea = value),
          onSoundChanged: (value) => setState(() => alertSound = value),
          onSmsChanged: (value) => setState(() => alertSms = value),
          onLogout: widget.onLogout,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav(
      {required this.current,
      required this.onChanged,
      required this.alertCount});

  final int current;
  final int alertCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.description_outlined, 'Health'),
      (Icons.notifications_none_rounded, 'Alerts'),
      (Icons.mic_none_rounded, 'Recordings'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = current == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              child: SizedBox(
                height: 66,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (selected)
                      Container(
                          width: 34,
                          height: 4,
                          decoration:
                              const BoxDecoration(color: AppTheme.teal)),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(items[index].$1,
                                  size: 27,
                                  color: selected
                                      ? AppTheme.teal
                                      : const Color(0xFF93A5B8)),
                              if (index == 2 && alertCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                          color: AppTheme.red,
                                          shape: BoxShape.circle)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            items[index].$2,
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppTheme.teal
                                    : const Color(0xFF8A9CAE)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GuardianHeader extends StatelessWidget {
  const _GuardianHeader({this.title = 'Guardian'}) : showShield = true;
  final String title;
  final bool showShield;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.navy,
                  letterSpacing: -.7)),
          const Spacer(),
          if (showShield)
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8FAF7), shape: BoxShape.circle),
              child: const Center(child: BadgeLogo(size: 34)),
            ),
        ],
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView(
      {super.key,
      required this.battery,
      required this.locationActive,
      required this.alertsToday,
      required this.guardiansWatching,
      required this.safeArea,
      required this.holdingSos,
      required this.onSosStart,
      required this.onSosCancel,
      required this.onAlerts});

  final int battery;
  final bool locationActive;
  final int alertsToday;
  final int guardiansWatching;
  final bool safeArea;
  final bool holdingSos;
  final VoidCallback onSosStart;
  final VoidCallback onSosCancel;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return _ScrollablePage(
      header: const _GuardianHeader(),
      children: [
        const Text('Hello, Eleanor 👋',
            style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy,
                letterSpacing: -.8)),
        const SizedBox(height: 8),
        Text('Your device is always on while it has battery. 🔋',
            style: TextStyle(fontSize: 17, color: AppTheme.muted)),
        const SizedBox(height: 26),
        _DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                        color: Color(0xFF42E69D), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                const Text('Device is Always On',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800))
              ]),
              const SizedBox(height: 12),
              Text(
                  'Your device stays active as long as it has battery. It never turns off on its own.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .66),
                      fontSize: 15,
                      height: 1.45)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: _StatusTile(
                        icon: '🔋', value: '$battery%', label: 'Battery')),
                const SizedBox(width: 14),
                const Expanded(
                    child: _StatusTile(
                        icon: '📶', value: 'Strong', label: 'Signal')),
                const SizedBox(width: 14),
                Expanded(
                    child: _StatusTile(
                        icon: '📍',
                        value: locationActive ? 'Active' : 'Off',
                        label: 'Location'))
              ]),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _WhiteCard(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('📍', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 9),
              const Text('Where are you?',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy)),
              const Spacer(),
              _Pill(
                  text: safeArea ? 'Safe Area ✓' : 'Outside Safe Area',
                  color: safeArea ? AppTheme.teal : AppTheme.red,
                  bg: safeArea ? AppTheme.tealSoft : AppTheme.redSoft)
            ]),
            const SizedBox(height: 14),
            _MapPreview(),
            const SizedBox(height: 13),
            const Text('42 Maple Ave, Springfield',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy)),
            const SizedBox(height: 4),
            const Text('Updated 4 minutes ago',
                style: TextStyle(fontSize: 15, color: AppTheme.muted)),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(
              child: _StatCard(
                  value: '$alertsToday',
                  valueColor: AppTheme.red,
                  title: 'Alerts sent today',
                  subtitle: 'Tap Alerts tab to see',
                  onTap: onAlerts)),
          const SizedBox(width: 14),
          const Expanded(
              child: _StatCard(
                  value: '2',
                  valueColor: AppTheme.teal,
                  title: 'People watching over you',
                  subtitle: 'Out of 3 guardians'))
        ]),
        const SizedBox(height: 24),
        _WhiteCard(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
          child: Column(children: [
            const Text('Need Help Right Now?',
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.navy)),
            const SizedBox(height: 16),
            Text(
                'Press and hold the red button for 2 seconds to alert everyone watching over you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16.5, height: 1.4, color: AppTheme.muted)),
            const SizedBox(height: 20),
            GestureDetector(
              onTapDown: (_) => onSosStart(),
              onTapUp: (_) => onSosCancel(),
              onTapCancel: onSosCancel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: holdingSos ? 160 : 150,
                height: holdingSos ? 160 : 150,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: holdingSos
                        ? const Color(0xFFC50B2C)
                        : const Color(0xFFE32945),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.red.withValues(alpha: .24),
                          blurRadius: 28,
                          spreadRadius: holdingSos ? 12 : 3)
                    ]),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('SOS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(holdingSos ? 'Keep holding...' : 'Hold 2 sec',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600))
                    ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 26),
      ],
    );
  }
}

class HealthView extends StatelessWidget {
  const HealthView(
      {super.key,
      required this.heartRate,
      required this.battery,
      required this.connected,
      required this.onToggleConnection,
      required this.onHeartRate,
      required this.onBack});
  final int heartRate;
  final int battery;
  final bool connected;
  final VoidCallback onToggleConnection;
  final ValueChanged<int> onHeartRate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final high = heartRate >= AppConstants.heartRateThreshold;
    return _ScrollablePage(
      children: [
        const SizedBox(height: 22),
        const Text('Device Health',
            style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy)),
        const SizedBox(height: 7),
        Text('A simple summary of how your device is doing today.',
            style: TextStyle(fontSize: 17, color: AppTheme.muted)),
        const SizedBox(height: 25),
        _DarkCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YOUR DEVICE',
              style: TextStyle(
                  color: Color(0xFF9BAABD),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8)),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _HealthMetric(label: 'Name', value: 'Guardian Pro X1')),
            Expanded(
                child: _HealthMetric(
                    label: 'Battery', value: '$battery% — Device is ON'))
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
                child: _HealthMetric(
                    label: 'Internet',
                    value: connected ? 'Connected ✓' : 'Disconnected')),
            Expanded(
                child:
                    _HealthMetric(label: 'Last active', value: '4 minutes ago'))
          ])
        ])),
        const SizedBox(height: 26),
        _WhiteCard(
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Heart Rate Monitor',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy)),
              const SizedBox(height: 6),
              Text('Alert threshold: ${AppConstants.heartRateThreshold} BPM',
                  style: TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 18),
              Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: high ? AppTheme.redSoft : AppTheme.tealSoft,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Icon(Icons.favorite_rounded,
                        color: high ? AppTheme.red : AppTheme.teal, size: 42),
                    const SizedBox(width: 16),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$heartRate BPM',
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: high ? AppTheme.red : AppTheme.navy)),
                          Text(
                              high
                                  ? 'Abnormal heart rate detected'
                                  : 'Within configured range',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: high ? AppTheme.red : AppTheme.teal,
                                  fontWeight: FontWeight.w700))
                        ])
                  ])),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onToggleConnection,
                        icon: Icon(connected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled),
                        label: Text(connected ? 'Connected' : 'Connect'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton(
                        onPressed: () =>
                            onHeartRate(AppConstants.heartRateThreshold),
                        child: const Text('Test 150 BPM')))
              ]),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => onHeartRate(82),
                  child: const Text('Reset to normal 82 BPM'))
            ])),
        const SizedBox(height: 22),
        _WhiteCard(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: AppTheme.teal, size: 30),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'The 150 BPM value is the project alert threshold, not a medical diagnosis.',
                      style: TextStyle(color: AppTheme.muted, height: 1.35))),
              const Icon(Icons.chevron_right, color: AppTheme.muted)
            ])),
        const SizedBox(height: 26),
      ],
    );
  }
}

class AlertsView extends StatelessWidget {
  const AlertsView(
      {super.key,
      required this.alerts,
      required this.onBack,
      required this.onMarkRead});
  final List<GuardianAlert> alerts;
  final VoidCallback onBack;
  final ValueChanged<GuardianAlert> onMarkRead;

  @override
  Widget build(BuildContext context) {
    final count = alerts.where((a) => a.isNew).length;
    return _ScrollablePage(
      children: [
        const SizedBox(height: 22),
        const Text('Your Alerts',
            style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy)),
        const SizedBox(height: 7),
        Text('These are the times your device sent an alert.',
            style: TextStyle(fontSize: 17, color: AppTheme.muted)),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.redSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Text(
                '🔔',
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'You have 1 new alert'
                          : 'You have $count new alerts',
                      style: const TextStyle(
                        color: AppTheme.red,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap on an alert below to see the details.',
                      style: TextStyle(
                        color: Color(0xFF9E5262),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AlertCard(alert: alert, onTap: () => onMarkRead(alert)))),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _AlertCard extends StatefulWidget {
  const _AlertCard({required this.alert, required this.onTap});
  final GuardianAlert alert;
  final VoidCallback onTap;
  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    final sos = a.kind == 'SOS' || a.kind == 'HEART RATE';
    return GestureDetector(
      onTap: () {
        setState(() => a.expanded = !a.expanded);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: a.isNew ? AppTheme.red : Colors.transparent,
                width: a.isNew ? 2 : 0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          Row(children: [
            Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    color: a.iconBg, borderRadius: BorderRadius.circular(18)),
                child: Center(
                    child: Icon(a.icon,
                        color: sos ? AppTheme.red : const Color(0xFF8C9BB3),
                        size: 29))),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy)),
                  const SizedBox(height: 5),
                  Text(a.time,
                      style: TextStyle(fontSize: 15, color: AppTheme.muted))
                ])),
            if (a.isNew)
              Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: AppTheme.red, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Icon(
                a.expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF91A2B4))
          ]),
          if (a.expanded) ...[
            const SizedBox(height: 15),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(a.subtitle ?? 'No additional details.',
                    style: TextStyle(
                        color: AppTheme.muted, fontSize: 15.5, height: 1.45))),
            const SizedBox(height: 12),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    a.isNew
                        ? 'New alert • Tap again to collapse'
                        : 'Alert details',
                    style: TextStyle(
                        color: sos ? AppTheme.red : AppTheme.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)))
          ]
        ]),
      ),
    );
  }
}

class RecordingsView extends StatelessWidget {
  const RecordingsView(
      {super.key,
      required this.playing,
      required this.progress,
      required this.onTogglePlay});
  final bool playing;
  final double progress;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    return _ScrollablePage(
      header: const _GuardianHeader(title: 'Recordings'),
      children: [
        const SizedBox(height: 27),
        const Text('Voice Recordings',
            style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                color: AppTheme.navy)),
        const SizedBox(height: 7),
        Text('Audio saved by your device. Tap the play button to listen.',
            style: TextStyle(fontSize: 17, color: AppTheme.muted)),
        const SizedBox(height: 25),
        _RecordingCard(
            title: 'SOS Alert Recording',
            meta: 'Today · 9:14 AM · 1:00 long',
            tag: 'Recorded during SOS',
            tagColor: AppTheme.red,
            total: '1:00',
            playing: playing,
            progress: progress,
            onPlay: onTogglePlay),
        const SizedBox(height: 20),
        _RecordingCard(
            title: 'My Own Recording',
            meta: 'Yesterday · 3:15 PM · 2:30 long',
            tag: 'You recorded this',
            tagColor: AppTheme.teal,
            total: '2:30',
            playing: playing,
            progress: progress,
            onPlay: onTogglePlay),
        const SizedBox(height: 20),
        _RecordingCard(
            title: 'SOS Alert Recording',
            meta: 'Aug 9 · 11:08 AM · 1:00 long',
            tag: 'Recorded during SOS',
            tagColor: AppTheme.red,
            total: '1:00',
            playing: false,
            progress: 0,
            onPlay: onTogglePlay),
        const SizedBox(height: 20),
        _RecordingCard(
            title: 'My Own Recording',
            meta: 'Aug 8 · 6:44 PM · 0:22 long',
            tag: 'You recorded this',
            tagColor: AppTheme.teal,
            total: '0:22',
            playing: false,
            progress: 0,
            onPlay: onTogglePlay),
        const SizedBox(height: 26),
      ],
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard(
      {required this.title,
      required this.meta,
      required this.tag,
      required this.tagColor,
      required this.total,
      required this.playing,
      required this.progress,
      required this.onPlay});
  final String title;
  final String meta;
  final String tag;
  final Color tagColor;
  final String total;
  final bool playing;
  final double progress;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onPlay,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppTheme.navy,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Pill(
            text: tag,
            color: tagColor,
            bg: tagColor.withValues(alpha: .10),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: CustomPaint(
              painter: _WavePainter(progress: progress),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0:00',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13,
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView(
      {super.key,
      required this.battery,
      required this.connected,
      required this.safeArea,
      required this.alertSound,
      required this.alertSms,
      required this.onSafeAreaChanged,
      required this.onSoundChanged,
      required this.onSmsChanged,
      required this.onLogout});
  final int battery;
  final bool connected;
  final bool safeArea;
  final bool alertSound;
  final bool alertSms;
  final ValueChanged<bool> onSafeAreaChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onSmsChanged;
  final VoidCallback onLogout;
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _GuardianPerson {
  _GuardianPerson(this.name, this.relation, this.phone, {this.pending = false});
  final String name;
  final String relation;
  final String phone;
  bool pending;
}

class _ProfileViewState extends State<ProfileView> {
  final List<_GuardianPerson> guardians = [
    _GuardianPerson('Sarah Johnson', 'Spouse', '+1 (555) 321-1000'),
    _GuardianPerson('Michael Chen', 'Brother', '+1 (555) 987-6543'),
    _GuardianPerson('Dr. Priya Nair', 'Physician', '+1 (555) 246-8012',
        pending: true),
  ];

  int get activeGuardians => guardians.where((g) => !g.pending).length;

  void removeGuardian(int index) {
    if (activeGuardians <= 1 && !guardians[index].pending) {
      _toast('At least one guardian must remain.');
      return;
    }
    setState(() => guardians.removeAt(index));
  }

  void addGuardian() {
    if (guardians.length >= 3) {
      _toast(
          'You have reached the maximum of 3 guardians. Remove one to add a new person.');
      return;
    }
    setState(() => guardians.add(_GuardianPerson(
        'New Guardian', 'Friend', '+1 (555) 000-0000',
        pending: true)));
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _alertSettings() async {
    bool sound = widget.alertSound;
    bool sms = widget.alertSms;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const Text('Change how alerts are sent'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      SwitchListTile(
                          title: const Text('App notifications'),
                          value: sound,
                          onChanged: (v) => setDialog(() => sound = v)),
                      SwitchListTile(
                          title: const Text('SMS to guardians'),
                          value: sms,
                          onChanged: (v) => setDialog(() => sms = v))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            widget.onSoundChanged(sound);
                            widget.onSmsChanged(sms);
                            Navigator.pop(context);
                          },
                          child: const Text('Save'))
                    ])));
  }

  Future<void> _safeAreaDialog() async {
    bool value = widget.safeArea;
    await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialog) => AlertDialog(
                    title: const Text('Set up or change my safe area'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Your current safe area is 42 Maple Ave, Springfield.'),
                      const SizedBox(height: 18),
                      SwitchListTile(
                          title: const Text('Safe area alerts'),
                          subtitle: const Text(
                              'Notify guardians when you leave this area.'),
                          value: value,
                          onChanged: (v) => setDialog(() => value = v))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            widget.onSafeAreaChanged(value);
                            Navigator.pop(context);
                          },
                          child: const Text('Save'))
                    ])));
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollablePage(
      header: const _GuardianHeader(title: 'Profile'),
      children: [
        const SizedBox(height: 22),
        _WhiteCard(
            padding: const EdgeInsets.all(22),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Device',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy)),
              const SizedBox(height: 18),
              _InfoRow(label: 'Device name', value: 'Guardian Pro X1'),
              _InfoRow(
                  label: 'Battery right now',
                  value: '${widget.battery}% — Device is ON'),
              _InfoRow(label: 'Software version', value: 'v3.4.1 (Latest)'),
              _InfoRow(label: 'Registered on', value: 'January 14, 2025')
            ])),
        const SizedBox(height: 22),
        _WhiteCard(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('People Who Watch Over You',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.navy)),
              const SizedBox(height: 8),
              Text(
                  'These people get a message when you press SOS or leave your safe area. You can have up to 3 guardians. There must always be at least 1.',
                  style: TextStyle(
                      fontSize: 15.5, height: 1.45, color: AppTheme.muted)),
              const SizedBox(height: 18),
              Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.tealSoft,
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    const Text('🛡️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                            '$activeGuardians active guardians · ${guardians.length >= 3 ? 'List is full (max 3)' : 'You can add another'}',
                            style: const TextStyle(
                                color: AppTheme.teal,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)))
                  ])),
              const SizedBox(height: 14),
              ...List.generate(
                  guardians.length,
                  (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GuardianCard(
                          person: guardians[i],
                          onRemove: () => removeGuardian(i)))),
              if (guardians.length < 3)
                Center(
                    child: OutlinedButton.icon(
                        onPressed: addGuardian,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add guardian'))),
              if (guardians.length >= 3)
                const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Center(
                        child: Text(
                            'You have reached the maximum of 3 guardians. Remove one to add a new person.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.muted, fontSize: 13.5))))
            ])),
        const SizedBox(height: 22),
        _SettingsCard(
            icon: '🔔',
            title: 'Change how alerts are sent',
            onTap: _alertSettings),
        const SizedBox(height: 1),
        _SettingsCard(
            icon: '📍',
            title: 'Set up or change my safe area',
            onTap: _safeAreaDialog),
        const SizedBox(height: 22),
        _WhiteCard(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.bluetooth, color: AppTheme.teal),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        widget.connected
                            ? 'Badge connected'
                            : 'Badge disconnected',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy))),
                Text(widget.connected ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                        color: widget.connected ? AppTheme.teal : AppTheme.red,
                        fontWeight: FontWeight.w800))
              ]),
              const Divider(height: 28),
              Row(children: [
                const Icon(Icons.lock_outline, color: AppTheme.muted),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Privacy & security',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right, color: AppTheme.muted)
              ])
            ])),
        const SizedBox(height: 18),
        SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
                onPressed: () {
                  widget.onLogout();
                },
                icon: const Icon(Icons.logout, color: AppTheme.red),
                label: const Text('Sign out',
                    style: TextStyle(
                        color: AppTheme.red, fontWeight: FontWeight.w700)))),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.person, required this.onRemove});
  final _GuardianPerson person;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pending = person.pending;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: pending ? Colors.white : const Color(0xFFF4FBFA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: pending ? const Color(0xFFD1DCE7) : AppTheme.teal,
                width: pending ? 1.5 : 2,
                style: pending ? BorderStyle.solid : BorderStyle.solid)),
        child: Column(children: [
          Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F7F4), shape: BoxShape.circle),
                child: Center(
                    child: Text(
                        person.name.startsWith('Dr.')
                            ? '🧑‍⚕️'
                            : person.name.startsWith('Sarah')
                                ? '💑'
                                : '👨‍👧',
                        style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Flexible(
                        child: Text(person.name,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: pending
                                    ? const Color(0xFF8FA0B2)
                                    : AppTheme.navy))),
                    if (pending) ...[
                      const SizedBox(width: 7),
                      _Pill(
                          text: 'Pending',
                          color: const Color(0xFFE38B20),
                          bg: const Color(0xFFFFF1DE))
                    ]
                  ]),
                  const SizedBox(height: 4),
                  Text(person.relation,
                      style: TextStyle(
                          color: pending
                              ? const Color(0xFF9BAABB)
                              : AppTheme.muted,
                          fontSize: 14)),
                  Text(person.phone,
                      style: TextStyle(
                          color: pending
                              ? const Color(0xFF9BAABB)
                              : AppTheme.muted,
                          fontSize: 14))
                ])),
            TextButton(
                onPressed: onRemove,
                child: const Text('Remove',
                    style: TextStyle(
                        color: AppTheme.red, fontWeight: FontWeight.w800)))
          ]),
          const SizedBox(height: 13),
          Divider(
              height: 1,
              color: pending ? AppTheme.border : const Color(0xFFD7EDEA)),
          const SizedBox(height: 11),
          Align(
              alignment: Alignment.centerLeft,
              child: _Pill(
                  text: pending
                      ? '⌛ Waiting for them to accept your request'
                      : '✓ Will be notified   SMS & App',
                  color: pending ? const Color(0xFFA96A13) : AppTheme.teal,
                  bg: pending ? const Color(0xFFFFF3E3) : AppTheme.tealSoft))
        ]));
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard(
      {required this.icon, required this.title, required this.onTap});
  final String icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
              child: Row(children: [
                Text(icon, style: const TextStyle(fontSize: 23)),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navy))),
                const Icon(Icons.chevron_right, color: AppTheme.muted)
              ]))));
}

class _ScrollablePage extends StatelessWidget {
  const _ScrollablePage({this.header, required this.children});
  final Widget? header;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(children: [
        if (header != null) header!,
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children)))
      ]);
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppTheme.navy, AppTheme.navy2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28)),
      child: child);
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard(
      {required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: child);
}

class _StatusTile extends StatelessWidget {
  const _StatusTile(
      {required this.icon, required this.value, required this.label});
  final String icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      height: 122,
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(14),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 27)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            style:
                TextStyle(color: Colors.white.withValues(alpha: .58), fontSize: 13.5))
      ]));
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.value,
      required this.valueColor,
      required this.title,
      required this.subtitle,
      this.onTap});
  final String value;
  final Color valueColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: _WhiteCard(
          padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 39,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: valueColor)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: AppTheme.muted))
          ])));
}

class _MapPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      height: 170,
      decoration: BoxDecoration(
          color: const Color(0xFFE8EDF4),
          borderRadius: BorderRadius.circular(18)),
      child: CustomPaint(
          painter: _MapPainter(),
          child: const Center(
              child: Icon(Icons.location_on_rounded,
                  color: Color(0xFFE42C45), size: 52))));
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFD6DDE7)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-20, size.height * .25),
        Offset(size.width + 20, size.height * .70), road);
    canvas.drawLine(Offset(size.width * .10, size.height + 20),
        Offset(size.width * .80, -20), road);
    final river = Paint()
      ..color = const Color(0xFFBBD7EA)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .75, -10)
      ..cubicTo(size.width * .50, size.height * .25, size.width * .95,
          size.height * .55, size.width * .70, size.height + 10);
    canvas.drawPath(path, river);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.bg});
  final String text;
  final Color color;
  final Color bg;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12.5, fontWeight: FontWeight.w800)));
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF95A6B8),
                fontSize: 14.5,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800))
      ]);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 16, color: AppTheme.muted))),
        const SizedBox(width: 16),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy)))
      ]));
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFFDCE3EF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = AppTheme.teal
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final count = 42;
    for (int i = 0; i < count; i++) {
      final x = 3 + i * (size.width - 6) / (count - 1);
      final h = 10 + ((i * 17) % 27).toDouble();
      final paint = i / count <= progress ? activePaint : barPaint;
      canvas.drawLine(Offset(x, size.height / 2 - h / 2),
          Offset(x, size.height / 2 + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
