/// Makes text comparable while searching: ignores case, Arabic diacritics and
/// the common spelling variants (أ/إ/آ/ا, ة/ه, ى/ي, ؤ/و, ئ/ي) and punctuation.
String normalizeForSearch(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp('[ً-ْـ]'), '') // tashkeel and kashida
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(RegExp("['’`]"), '')
      .replaceAll(RegExp(r'[-_.,()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Scores [haystack] against [query]. Null means no match; lower is a better match.
/// Every word of the query must appear, in any order.
int? searchScore(String haystack, String query) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return 0;
  final h = normalizeForSearch(haystack);
  if (!q.split(' ').every(h.contains)) return null;
  if (h.startsWith(q)) return 0;
  if (h.contains(' $q')) return 1;
  return 2;
}

/// Sorts names the way a reader expects, ignoring spelling variants.
int compareForSearch(String a, String b) => normalizeForSearch(a).compareTo(normalizeForSearch(b));
