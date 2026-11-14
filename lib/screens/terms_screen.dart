import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// Version of the Terms the user accepts at sign-up. Bump it when the text changes.
const kTermsVersion = '2026-11-09';

/// Opens the Terms and Conditions as a full page, like the legal pages of most
/// apps: app bar with back arrow, document title and date, readable sections.
/// With [showAgree], a sticky "I agree" bar is shown (enabled once scrolled to
/// the end) and the page returns `true` when tapped.
Future<bool?> showTermsSheet(BuildContext context, {bool showAgree = false}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => TermsScreen(showAgree: showAgree), fullscreenDialog: showAgree),
  );
}

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, this.showAgree = false});
  final bool showAgree;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final _scroll = ScrollController();
  _TermsDoc? _doc;
  String? _lang;

  /// The Agree button only unlocks after the user has scrolled to the end.
  bool _reachedEnd = false;

  void _checkEnd() {
    if (_reachedEnd || !_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 24) setState(() => _reachedEnd = true);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_checkEnd);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = context.app.lang;
    if (lang != _lang) {
      _lang = lang;
      rootBundle.loadString('assets/terms/terms_$lang.md').then((md) {
        if (mounted) setState(() => _doc = _TermsDoc.parse(md));
        // Short enough to fit without scrolling? Then it counts as read.
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnd());
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final doc = _doc;
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: .5,
        shadowColor: AppColors.line,
        centerTitle: true,
        leading: IconButton(
          tooltip: app.t(widget.showAgree ? 'close' : 'back'),
          icon: Icon(widget.showAgree ? Icons.close_rounded : Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(app.t('terms'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: doc == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(18, 8, 18, widget.showAgree ? 20 : 20 + mq.padding.bottom),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(doc.updated, style: TextStyle(fontSize: 11, color: AppColors.hint)),
                  const SizedBox(height: 10),
                  for (final p in doc.intro) ...[
                    _Body(p, color: AppColors.ink),
                    const SizedBox(height: 4),
                  ],
                  for (final s in doc.sections) _SectionView(s),
                  const SizedBox(height: 22),
                  Center(child: Image.asset('assets/images/logo_drop.png', height: 18)),
                ]),
              ),
            ),
      bottomNavigationBar: !widget.showAgree
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + mq.padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: PrimaryButton(
                label: app.t(_reachedEnd ? 'agree' : 'scrollToAgree'),
                height: 44,
                radius: 999,
                onPressed: _reachedEnd ? () => Navigator.of(context).pop(true) : null,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parsing the small Markdown subset the terms use (#, ##, -, 1., **bold**, tables)

class _TermsDoc {
  _TermsDoc(this.title, this.updated, this.intro, this.sections);
  final String title, updated;
  final List<String> intro;
  final List<_Section> sections;

  static _TermsDoc parse(String md) {
    var title = '', updated = '';
    final intro = <String>[];
    final sections = <_Section>[];
    final lines = md.split('\n');
    var i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }
      if (line.startsWith('# ')) {
        title = line.substring(2);
      } else if (line.startsWith('## ')) {
        final h = line.substring(3);
        final m = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(h);
        sections.add(_Section(m?.group(1) ?? '', m?.group(2) ?? h));
      } else if (line.startsWith('|')) {
        final rows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          final cells = lines[i].trim().split('|').map((c) => c.trim()).toList()
            ..removeAt(0);
          if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
          if (!cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) {
            rows.add(cells);
          }
          i++;
        }
        sections.last.blocks.add(_Block.table(rows));
        continue;
      } else if (sections.isEmpty) {
        // Before the first section: date line, then intro paragraphs
        if (updated.isEmpty && intro.isEmpty) {
          updated = line;
        } else {
          intro.add(line);
        }
      } else if (line.startsWith('- ')) {
        sections.last.blocks.add(_Block.item('•', line.substring(2)));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final m = RegExp(r'^(\d+)\. (.*)$').firstMatch(line)!;
        sections.last.blocks.add(_Block.item('${m.group(1)}.', m.group(2)!));
      } else {
        sections.last.blocks.add(_Block.para(line));
      }
      i++;
    }
    return _TermsDoc(title, updated, intro, sections);
  }
}

class _Section {
  _Section(this.number, this.title);
  final String number, title;
  final key = GlobalKey();
  final blocks = <_Block>[];
}

class _Block {
  _Block.para(this.text)
      : marker = null,
        rows = null;
  _Block.item(this.marker, this.text) : rows = null;
  _Block.table(this.rows)
      : text = '',
        marker = null;
  final String text;
  final String? marker;
  final List<List<String>>? rows;
}

// ---------------------------------------------------------------------------
// Views

class _SectionView extends StatelessWidget {
  const _SectionView(this.s);
  final _Section s;

  @override
  Widget build(BuildContext context) {
    return Column(
        key: s.key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(children: [
              if (s.number.isNotEmpty)
                TextSpan(
                    text: '${s.number}.  ',
                    style: TextStyle(
                        fontFamily: AppFonts.latin, color: AppColors.hint)),
              TextSpan(text: s.title),
            ]),
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 6),
          for (final b in s.blocks)
            if (b.rows != null)
              _TableView(b.rows!)
            else if (b.marker != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 18,
                        child: Text(b.marker!,
                            style: TextStyle(
                                fontFamily: AppFonts.latin,
                                fontSize: 12,
                                height: 1.6,
                                color: AppColors.hint)),
                      ),
                      Expanded(child: _Body(b.text)),
                    ]),
              )
            else
              Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _Body(b.text)),
        ]);
  }
}

/// Reading text: 12.5px (small, like legal pop-ups), comfortable line height, **bold** support.
class _Body extends StatelessWidget {
  const _Body(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(children: [
        for (var k = 0; k < parts.length; k++)
          TextSpan(
              text: parts[k],
              style: k.isOdd
                  ? TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)
                  : null),
      ]),
      style: TextStyle(
          fontSize: 12.5, height: 1.6, color: color ?? AppColors.muted),
    );
  }
}

/// A table as a bordered list: first cell as the row title, other cells labelled by their column header.
class _TableView extends StatelessWidget {
  const _TableView(this.rows);
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.length < 2) return const SizedBox.shrink();
    final head = rows.first;
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var r = 1; r < rows.length; r++) ...[
          if (r > 1) Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rows[r].first,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              for (var c = 1; c < rows[r].length; c++) ...[
                const SizedBox(height: 4),
                if (c < head.length)
                  Text(head[c],
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.hint)),
                const SizedBox(height: 1),
                Text(rows[r][c],
                    style: TextStyle(
                        fontSize: 11.5, height: 1.5, color: AppColors.muted)),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

/// "☐ I have read and agree to the Terms and Conditions." The link opens the
/// terms with an Agree button; tapping Agree ticks the box.
class TermsAgreeTile extends StatefulWidget {
  const TermsAgreeTile(
      {super.key,
      required this.value,
      required this.onChanged,
      this.error = false,
      this.text});
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Plain statement instead of the default "…agree to the Terms and Conditions" line.
  final String? text;

  /// Shows the line in red (e.g. after tapping Next without ticking).
  final bool error;

  @override
  State<TermsAgreeTile> createState() => _TermsAgreeTileState();
}

class _TermsAgreeTileState extends State<TermsAgreeTile> {
  late final _tap = TapGestureRecognizer()..onTap = _openTerms;

  Future<void> _openTerms() async {
    final agreed = await showTermsSheet(context, showAgree: true);
    if (agreed == true) widget.onChanged(true);
  }

  /// The Terms tick opens the Terms (it gets ticked by tapping "I agree" at the end);
  /// a plain statement just toggles. Unticking is always direct.
  void _toggle() {
    if (widget.text == null && !widget.value) {
      _openTerms();
    } else {
      widget.onChanged(!widget.value);
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: widget.value,
          onChanged: (_) => _toggle(),
          activeColor: AppColors.red,
          side: BorderSide(
              color: widget.error ? AppColors.error : AppColors.hint,
              width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text.rich(
              TextSpan(children: [
                if (widget.text != null)
                  TextSpan(text: widget.text)
                else ...[
                  TextSpan(text: app.t('agreeA')),
                  TextSpan(
                    text: app.t('terms'),
                    style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline),
                    recognizer: _tap,
                  ),
                  TextSpan(text: app.t('agreeB')),
                ],
              ]),
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: widget.error ? AppColors.error : AppColors.muted),
            ),
          ),
        ),
      ]),
    );
  }
}
