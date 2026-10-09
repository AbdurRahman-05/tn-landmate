import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OfficialSourceCard extends StatelessWidget {
  final String title;
  final String description;
  final String url;
  final VoidCallback? onTap;

  const OfficialSourceCard({
    Key? key,
    required this.title,
    required this.description,
    required this.url,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance, color: AppColors.forestGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.charcoal),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Official Portal', style: TextStyle(fontSize: 10, color: AppColors.forestGreen, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: AppColors.charcoalLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(fontSize: 10, color: AppColors.forestGreen, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.charcoalLight),
          ],
        ),
      ),
    );
  }
}
