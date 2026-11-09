import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/request_card.dart';
import '../sheets/request_detail_sheet.dart';

/// Public feed of open blood requests, with search and an "Urgent" filter.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  Urgency? _filter;
  late Future<List<BloodRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<BloodRequest>> _fetch() =>
      context.appRead.api.feed(urgency: _filter, query: _search.text.trim());

  void _load() => setState(() => _future = _fetch());

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(app.t('feed'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: app.t('searchHint'),
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.hint),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted2),
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 42),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _FilterChip(label: app.t('all'), selected: _filter == null, onTap: () { _filter = null; _load(); }),
          const SizedBox(width: 8),
          _FilterChip(label: app.t('urgent'), selected: _filter == Urgency.urgent, onTap: () { _filter = Urgency.urgent; _load(); }),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<BloodRequest>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
              }
              if (snap.hasError) return ErrorState(message: app.errorText(snap.error!), onRetry: _load);
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return EmptyState(title: app.t('noResults'), subtitle: app.t('noResultsSub'), pose: MascotPose.phone);
              }
              return RefreshIndicator(
                color: AppColors.red,
                onRefresh: () async => _load(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return RequestCard(
                      request: r,
                      onTap: () => showRequestDetailSheet(context, r).then((_) => _load()),
                      action: SoftButton(
                        label: app.t('details'),
                        onPressed: () => showRequestDetailSheet(context, r).then((_) => _load()),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.ink : AppColors.field),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.muted)),
        ),
      );
}
