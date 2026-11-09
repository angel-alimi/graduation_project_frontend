import 'package:flutter/material.dart';

import '../core/search.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import 'common.dart';

/// One row in a [SearchPickerField].
class PickerOption<T> {
  const PickerOption({required this.value, required this.label, this.subtitle, this.searchText = ''});
  final T value;
  final String label;
  final String? subtitle;

  /// Extra text to match, e.g. the name in the other language.
  final String searchText;
}

/// A form field that opens a sheet with a search box and a filtered list.
class SearchPickerField<T> extends StatelessWidget {
  const SearchPickerField({
    super.key,
    required this.options,
    required this.value,
    required this.hint,
    required this.searchHint,
    required this.onChanged,
    this.errorText,
  });

  final List<PickerOption<T>> options;
  final T? value;
  final String hint;
  final String searchHint;
  final ValueChanged<T> onChanged;
  final String? errorText;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.bg,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _PickerSheet<T>(options: options, selected: value, title: hint, searchHint: searchHint),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    String? label;
    for (final o in options) {
      if (o.value == value) label = o.label;
    }
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          errorText: errorText,
          errorMaxLines: 2,
          suffixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
        ),
        child: Text(
          label ?? hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: label == null ? AppColors.hint : AppColors.ink),
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({required this.options, required this.selected, required this.title, required this.searchHint});
  final List<PickerOption<T>> options;
  final T? selected;
  final String title;
  final String searchHint;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  /// Best matches first; options with the same score keep their given order.
  List<PickerOption<T>> get _results {
    final scored = <(int, int, PickerOption<T>)>[];
    for (var i = 0; i < widget.options.length; i++) {
      final o = widget.options[i];
      final score = searchScore('${o.label} ${o.searchText}', _query);
      if (score != null) scored.add((score, i, o));
    }
    scored.sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return [for (final s in scored) s.$3];
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final results = _results;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * .85,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 18))),
                SquareIconButton(icon: Icons.close_rounded, size: 36, tooltip: context.tr('close'), onPressed: () => Navigator.of(context).pop()),
              ]),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ]),
          ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Text(context.tr('noResults'), style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(indent: 12, endIndent: 12),
                    itemBuilder: (context, i) {
                      final o = results[i];
                      final selected = o.value == widget.selected;
                      return ListTile(
                        title: Text(o.label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w800 : FontWeight.w400)),
                        subtitle: o.subtitle == null ? null : Text(o.subtitle!, style: Theme.of(context).textTheme.bodySmall),
                        trailing: selected ? Icon(Icons.check_rounded, color: AppColors.ink) : null,
                        onTap: () => Navigator.of(context).pop(o.value),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

/// Sorts a list of labelled options by name, using [compareForSearch].
List<PickerOption<T>> sortedOptions<T>(Iterable<PickerOption<T>> options) =>
    options.toList()..sort((a, b) => compareForSearch(a.label, b.label));
