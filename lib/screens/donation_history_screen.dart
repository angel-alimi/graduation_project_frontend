import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/badges.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// The user's donation record, newest first.
class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.appRead.loadDonations();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final list = app.donations;

    Widget body;
    if (_error != null && list == null) {
      body = ErrorState(message: app.errorText(_error!), onRetry: _load);
    } else if (list == null) {
      body = const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    } else if (list.isEmpty) {
      body = EmptyState(title: app.t('noDonations'), subtitle: app.t('noDonationsSub'));
    } else {
      body = RefreshIndicator(
        color: AppColors.red,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: IntrinsicHeight(
                child: Row(children: [
                  _Stat(value: '${list.length}', label: app.t('statDonations')),
                  const VerticalDivider(width: 1),
                  _Stat(value: '${livesHelped(list)}', label: app.t('statLives')),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ListGroup(children: [
              for (final d in list) _DonationRow(d),
            ]),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PageHeader(app.t('donationRecord')),
            const SizedBox(height: 16),
            Expanded(child: body),
          ]),
        ),
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  const _DonationRow(this.d);
  final Donation d;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final place = d.hospitalId == null ? null : app.hospitalName(d.hospitalId!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(Icons.water_drop_outlined, size: 20, color: AppColors.muted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatDate(d.date, app.lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            Text(place == null || place.isEmpty ? app.t('wholeBlood') : place,
                style: TextStyle(fontSize: 12.5, color: AppColors.hint)),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontFamily: AppFonts.latin, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.hint)),
        ]),
      );
}
