/// Result of a [SheetMergeEngine.merge] call.
///
/// [headers] is row 1; [rows] are subsequent data rows already aligned to
/// [headers] and sorted ascending by the (ISO) date key in column A.
///
/// The display value in column A is already formatted by the caller-provided
/// `formatDateCell` — [rows] is ready to be written to Sheets as-is.
class SheetMergeResult {
  final List<Object?> headers;
  final List<List<Object?>> rows;
  final int addedDates;
  final int updatedDates;

  const SheetMergeResult({
    required this.headers,
    required this.rows,
    required this.addedDates,
    required this.updatedDates,
  });
}

/// Pure, synchronous merge logic for the Sheets export pipeline.
///
/// Sheet structure contract:
///   - Row 1 is the header row.
///   - Column A is the date column. Its displayed value is formatted by
///     [formatDateCell]; internally the merge engine keeps an ISO
///     (`yyyy-MM-dd`) key so sort order and map lookups are stable across
///     locales and display formats.
///
/// Merge rules:
///   - The date header cell (column A) is always rewritten to [dateHeader].
///   - Existing column headers listed as a key in [legacyHeaderMap] are
///     renamed in-place to the current header (schema migration). If the
///     new header already exists, the legacy column is dropped and its
///     values merge into the current column (new values from the caller
///     win; otherwise legacy value is preserved).
///   - Final column order: `[dateHeader, ...orderedSelectedHeaders,
///     ...unknown existing headers in their original order]`.
///   - For dates already in the sheet, only columns in [orderedSelectedHeaders]
///     are overwritten; other columns are preserved.
///   - New values that are `null` do NOT erase an existing cell.
///   - For dates not yet present, a new row is appended. Cells outside
///     the selected headers are left empty.
///   - Output rows are sorted ascending by the ISO date key; the displayed
///     cell uses [formatDateCell].
///   - Existing rows whose column A cannot be parsed via [parseIsoDate] are
///     dropped (they're considered schema-incompatible garbage — predictable
///     correctness over silent retention).
abstract final class SheetMergeEngine {
  static SheetMergeResult merge({
    required List<List<Object?>> existing,
    required String dateHeader,
    required List<String> orderedSelectedHeaders,
    required Map<String, String> legacyHeaderMap,
    required Map<String, Map<String, Object?>> newRowsByIsoDate,
    required String Function(String isoDate) formatDateCell,
    required String? Function(String raw) parseIsoDate,
  }) {
    final hasExistingHeader = existing.isNotEmpty && existing.first.isNotEmpty;

    // ── Normalize existing headers (apply legacy rename + date header) ──────
    final rawExistingHeaders = hasExistingHeader
        ? [for (final h in existing.first) h?.toString() ?? '']
        : <String>[];

    // Build the post-rename header list. Keep track of which existing-index
    // maps to which final header, so we can rebuild data rows with migrated
    // column names.
    final renamedHeaders = <String>[];
    for (var i = 0; i < rawExistingHeaders.length; i++) {
      if (i == 0) {
        renamedHeaders.add(dateHeader);
        continue;
      }
      final raw = rawExistingHeaders[i];
      final renamed = legacyHeaderMap[raw] ?? raw;
      renamedHeaders.add(renamed);
    }

    // Deduplicate (a legacy rename could collide with an existing current
    // header). First occurrence wins for the column position.
    final seen = <String>{};
    final dedupedHeaders = <String>[];
    final keptExistingIndices = <int>[];
    for (var i = 0; i < renamedHeaders.length; i++) {
      final h = renamedHeaders[i];
      if (h.isEmpty) continue;
      if (seen.add(h)) {
        dedupedHeaders.add(h);
        keptExistingIndices.add(i);
      }
    }

    // ── Compute final column order ──────────────────────────────────────────
    //   [dateHeader, ...orderedSelectedHeaders, ...unknown existing cols]
    final finalHeaders = <String>[dateHeader];
    final orderedSet = {dateHeader, ...orderedSelectedHeaders};
    for (final h in orderedSelectedHeaders) {
      if (h == dateHeader) continue;
      if (!finalHeaders.contains(h)) finalHeaders.add(h);
    }
    for (final h in dedupedHeaders) {
      if (orderedSet.contains(h)) continue;
      if (!finalHeaders.contains(h)) finalHeaders.add(h);
    }

    // ── Index existing rows by ISO date ─────────────────────────────────────
    // Map<isoDate, Map<header, value>>. Renamed headers are used here so
    // legacy data transparently shows up under the current header.
    final existingByIso = <String, Map<String, Object?>>{};
    for (var r = 1; r < existing.length; r++) {
      final row = existing[r];
      if (row.isEmpty) continue;
      final rawKey = row.first?.toString().trim() ?? '';
      if (rawKey.isEmpty) continue;
      final iso = parseIsoDate(rawKey);
      if (iso == null) continue;

      final map = existingByIso.putIfAbsent(iso, () => <String, Object?>{});
      for (final existingIdx in keptExistingIndices) {
        if (existingIdx == 0) continue;
        if (existingIdx >= row.length) continue;
        final finalHeader = renamedHeaders[existingIdx];
        if (finalHeader.isEmpty) continue;
        final value = row[existingIdx];
        if (value == null) continue;
        // First non-null wins when duplicates collide (legacy + current in
        // the same row for the same date).
        map.putIfAbsent(finalHeader, () => value);
      }
    }

    // ── Apply new rows on top of existing ───────────────────────────────────
    var added = 0;
    var updated = 0;
    final selectedSet = orderedSelectedHeaders.toSet();

    for (final entry in newRowsByIsoDate.entries) {
      final iso = entry.key;
      final incoming = entry.value;
      final current = existingByIso[iso];
      if (current == null) {
        added++;
        existingByIso[iso] = {
          for (final h in selectedSet)
            if (incoming[h] != null) h: incoming[h],
        };
      } else {
        updated++;
        for (final h in selectedSet) {
          final v = incoming[h];
          if (v == null) continue;
          current[h] = v;
        }
      }
    }

    // ── Build the final grid, sorted by ISO date ascending ─────────────────
    final isoDates = existingByIso.keys.toList()..sort();
    final rows = <List<Object?>>[
      for (final iso in isoDates)
        [
          formatDateCell(iso),
          for (var i = 1; i < finalHeaders.length; i++)
            existingByIso[iso]![finalHeaders[i]],
        ],
    ];

    return SheetMergeResult(
      headers: finalHeaders,
      rows: rows,
      addedDates: added,
      updatedDates: updated,
    );
  }
}
