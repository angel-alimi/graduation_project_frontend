import 'package:flutter/material.dart';

import 'models.dart';

/// A reward the user earns by donating or responding to requests.
class BadgeDef {
  final String key; // strings: badge_<key>, badge_<key>_d
  final IconData icon;
  final int goal;

  /// How far the user is towards [goal].
  final int Function(AppUser user, List<Donation> donations) progress;

  const BadgeDef(this.key, this.icon, this.goal, this.progress);

  bool earned(AppUser u, List<Donation> d) => progress(u, d) >= goal;
}

int _donated(AppUser _, List<Donation> d) => d.length;

/// All badges, in the order they are usually earned.
final List<BadgeDef> kBadges = [
  const BadgeDef('first', Icons.water_drop_outlined, 1, _donated),
  BadgeDef('responder', Icons.volunteer_activism_outlined, 1, (u, _) => u.responsesCount),
  const BadgeDef('three', Icons.favorite_border_rounded, 3, _donated),
  const BadgeDef('five', Icons.workspace_premium_outlined, 5, _donated),
  const BadgeDef('ten', Icons.military_tech_outlined, 10, _donated),
];

/// One donation can help up to three people.
int livesHelped(List<Donation> d) => d.length * 3;
