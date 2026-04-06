import 'package:flutter/material.dart';

import '../../../../app/theme/yeolpumta_theme.dart';

class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget quickActionTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required String trailing,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: YeolpumtaTheme.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: YeolpumtaTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: YeolpumtaTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: YeolpumtaTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  color: YeolpumtaTheme.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget sectionTitle(String value) {
  return Text(
    value,
    style: const TextStyle(
      color: YeolpumtaTheme.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

InputDecoration fieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: YeolpumtaTheme.textSecondary),
    prefixIcon: Icon(icon, color: YeolpumtaTheme.accent),
    suffixIcon: suffix,
    filled: true,
    fillColor: YeolpumtaTheme.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: YeolpumtaTheme.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: YeolpumtaTheme.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: YeolpumtaTheme.accent, width: 1.4),
    ),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
