import 'package:flutter/material.dart';

class DisclaimerBanner extends StatelessWidget {
  final String text;
  final bool isDemo;

  const DisclaimerBanner({
    Key? key,
    required this.text,
    this.isDemo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDemo ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDemo ? const Color(0xFFF59E0B) : const Color(0xFF93C5FD),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDemo ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 20,
            color: isDemo ? const Color(0xFFB45309) : const Color(0xFF1D4ED8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDemo ? const Color(0xFF92400E) : const Color(0xFF1E40AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
