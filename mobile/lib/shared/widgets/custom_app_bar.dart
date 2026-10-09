import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLanguageSwitch;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showLanguageSwitch = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);

    return AppBar(
      title: Text(title),
      backgroundColor: AppColors.forestGreen,
      actions: [
        if (showLanguageSwitch)
          TextButton(
            onPressed: () {
              ref.read(languageProvider.notifier).toggle();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedGold,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.mutedGold),
                const SizedBox(width: 4),
                Text(
                  currentLang == 'ta' ? 'English' : 'தமிழ்',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ...?actions,
      ],
    );
  }
}
