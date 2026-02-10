import 'package:flutter/material.dart';

Widget buildSearchBar({
  required TextEditingController controller,
  required String hint,
  required ValueChanged<String> onChanged,
  required VoidCallback onClear,
}) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

Widget buildDebugCard({
  required IconData icon,
  required Color iconColor,
  required String title,
  String? subtitle,
  String? trailing,
  String? extra,
  Widget? extraWidget,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (extra != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              extra,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
        if (extraWidget != null) ...[const SizedBox(height: 8), extraWidget],
      ],
    ),
  );
}

Widget emptyState(IconData icon, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white10, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: Colors.white24, fontSize: 14),
        ),
      ],
    ),
  );
}

Widget detailRow(String label, String value) {
  return Row(
    children: [
      Text(
        '$label: ',
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ],
  );
}

String formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}
