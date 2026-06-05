import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/check_provider.dart';
import 'core/providers/news_provider.dart';
import 'core/providers/streak_provider.dart';
import 'features/home/home_screen.dart';
import 'features/truth_lens/truth_lens_screen.dart';
import 'features/trust_feed/trust_feed_screen.dart';
import 'features/trace_iq/trace_iq_screen.dart';
import 'features/ask_iq/ask_iq_screen.dart';
import 'features/streak/streak_screen.dart';

class LensIQApp extends StatelessWidget {
  const LensIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CheckProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'LensIQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    TruthLensScreen(),
    TrustFeedScreen(),
    TraceIQScreen(),
    AskIQScreen(),
    StreakScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF141830),
        indicatorColor: const Color(0xFF00D4FF).withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF00D4FF)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.policy_outlined),
            selectedIcon: Icon(Icons.policy_rounded, color: Color(0xFF00D4FF)),
            label: 'Truth Lens',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed_rounded, color: Color(0xFF00D4FF)),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search_rounded, color: Color(0xFF00D4FF)),
            label: 'TraceIQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: Color(0xFF00D4FF)),
            label: 'AskIQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_outlined),
            selectedIcon: Icon(Icons.local_fire_department_rounded, color: Color(0xFF00D4FF)),
            label: 'Streak',
          ),
        ],
      ),
    );
  }
}
