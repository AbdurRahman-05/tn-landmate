import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/translations.dart';
import '../core/providers.dart';
import 'home/home_screen.dart';
import 'land_search/land_search_screen.dart';
import 'calculators/area_converter_screen.dart';
import 'properties/saved_properties_screen.dart';
import 'profile/profile_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LandSearchScreen(),
    AreaConverterScreen(),
    SavedPropertiesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppTranslations.get('home', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.travel_explore_outlined),
            activeIcon: const Icon(Icons.travel_explore),
            label: AppTranslations.get('land_search', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate),
            label: AppTranslations.get('tools', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_outline),
            activeIcon: const Icon(Icons.bookmark),
            label: AppTranslations.get('saved_properties', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppTranslations.get('profile', lang),
          ),
        ],
      ),
    );
  }
}
