// lib/widgets/status_badge.dart
// Coloured chip for displaying PO status.

import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status.toLowerCase()) {
      'open'      => ('Open',      Colors.blue),
      'partial'   => ('Partial',   Colors.orange),
      'complete'  => ('Complete',  Colors.green),
      'cancelled' => ('Cancelled', Colors.grey),
      _           => (status,      Colors.blueGrey),
    };

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
