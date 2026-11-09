import 'package:flutter/material.dart';

import 'models.dart';

/// The donor's level. It only goes up with confirmed donations.
/// Strings: `badge_<key>` (name) and `badge_<key>_d` (what it takes).
class DonorLevel {
  final String key;
  final IconData icon;

  /// Confirmed donations needed to reach this level.
  final int minDonations;

  const DonorLevel(this.key, this.icon, this.minDonations);
}

/// All levels, lowest first.
const List<DonorLevel> kLevels = [
  DonorLevel('new', Icons.water_drop_outlined, 0),
  DonorLevel('first', Icons.water_drop_rounded, 1),
  DonorLevel('three', Icons.favorite_rounded, 3),
  DonorLevel('five', Icons.workspace_premium_rounded, 5),
  DonorLevel('ten', Icons.military_tech_rounded, 10),
];

/// The level for [donations] confirmed donations.
DonorLevel levelFor(int donations) => kLevels.lastWhere((l) => donations >= l.minDonations);

/// The next level to reach, or null at the top.
DonorLevel? nextLevel(int donations) {
  for (final l in kLevels) {
    if (l.minDonations > donations) return l;
  }
  return null;
}

/// One donation can help up to three people.
int livesHelped(List<Donation> d) => d.length * 3;
