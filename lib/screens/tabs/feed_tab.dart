import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/request_card.dart';
import '../sheets/request_detail_sheet.dart';

/// Public feed of open blood requests. One search icon next to the title
/// opens the search field in its place; the back arrow closes it and clears the search.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  bool _searching = false;
  Timer? _debounce;
  late Future<List<BloodRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<BloodRequest>> _fetch() =>
      context.appRead.api.feed(query: _search.text.trim());

  void _load() => setState(() => _future = _fetch());

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  void _openSearch() {
    setState(() => _searching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _closeSearch() {
    _focus.unfocus();
    final had = _search.text.isNotEmpty;
    _search.clear();
    setState(() => _searching = false);
    if (had) _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.dispose();
    _search.dispose();
    super.dispose();
  }

  Widget _titleRow(AppState app) =>
      Row(key: const ValueKey('title'), children: [
        Expanded(
            child: Text(app.t('feed'),
                style: Theme.of(context).textTheme.titleLarge)),
        SquareIconButton(
          icon: Icons.search_rounded,
          size: 40,
          filled: true,
          tooltip: app.t('searchHint'),
          onPressed: _openSearch,
        ),
      ]);

  Widget _searchField(AppState app) =>
      Row(key: const ValueKey('search'), children: [
        IconButton(
          tooltip: app.t('back'),
          onPressed: _closeSearch,
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
        ),
        Expanded(
          child: TextField(
            controller: _search,
            focusNode: _focus,
            onChanged: (v) {
              setState(() {}); // shows / hides the clear button
              _onSearch(v);
            },
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: app.t('searchHint'),
              hintStyle: TextStyle(fontSize: 13.5, color: AppColors.hint),
              filled: true,
              fillColor: AppColors.chip,
              contentPadding:
                  const EdgeInsetsDirectional.fromSTEB(16, 11, 8, 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: app.t('clear'),
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.muted),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                        _load();
                      },
                    ),
            ),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    // While searching, the system back button closes the search first.
    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: _searching ? _searchField(app) : _titleRow(app),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<BloodRequest>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4));
                }
                if (snap.hasError) {
                  return ErrorState(
                      message: app.errorText(snap.error!), onRetry: _load);
                }
                final list = snap.data ?? const [];
                if (list.isEmpty) {
                  return EmptyState(
                      title: app.t('noResults'),
                      subtitle: app.t('noResultsSub'),
                      icon: Icons.search_off_rounded);
                }
                return RefreshIndicator(
                  color: AppColors.redText,
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final r = list[i];
                      void open() => showRequestDetailSheet(context, r)
                          .then((_) => _load());
                      return RequestCard(
                        request: r,
                        onTap: open,
                        actions: [
                          PostAction(label: app.t('details'), subtle: true, onTap: open),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
