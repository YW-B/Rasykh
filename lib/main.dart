import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/quran_repository.dart';
import 'data/progress_repository.dart';
import 'theme/app_theme.dart';
import 'widgets/ambient_background.dart';
import 'screens/library_screen.dart';
import 'screens/memorize_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/progress_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkerEmerald,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Load Quran data and memorization progress before app starts.
  await QuranRepository().init();
  await ProgressController().init();
  runApp(const RasykhApp());
}

class RasykhApp extends StatelessWidget {
  const RasykhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rasykh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

/// Root scaffold with bottom navigation and ambient background.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    LibraryScreen(),
    MemorizeScreen(),
    QuizScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Ambient animated background
          const AmbientBackground(),

          // Active screen (IndexedStack keeps state)
          IndexedStack(index: _currentIndex, children: _screens),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.menu_book_outlined, Icons.menu_book, 'Library'),
              _navItem(
                1,
                Icons.play_circle_outline,
                Icons.play_circle,
                'Memorize',
              ),
              _navItem(2, Icons.mic_none_outlined, Icons.mic, 'Quiz'),
              _navItem(
                3,
                Icons.bar_chart_outlined,
                Icons.bar_chart,
                'Progress',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.transparent,
            ),
            child: Icon(
              isActive ? iconFilled : iconOutlined,
              size: 24,
              color: isActive
                  ? AppColors.emerald400
                  : AppColors.emerald100.withValues(alpha: 0.50),
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emerald400,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: 0.60),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
