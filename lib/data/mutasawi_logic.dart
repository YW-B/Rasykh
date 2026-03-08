import 'mock_data.dart';

/// A contiguous page-sized slice of ayat from a surah.
///
/// For example, a surah with 23 ayat and chunkSize=10 produces:
///   Chunk 0: ayah 1–10  (10 ayat)
///   Chunk 1: ayah 11–20 (10 ayat)
///   Chunk 2: ayah 21–23 ( 3 ayat)
class MemorizationChunk {
  /// Zero-based index of this chunk within the surah.
  final int index;

  /// The ayat in this chunk.
  final List<Ayah> ayat;

  const MemorizationChunk({required this.index, required this.ayat});

  /// Human-readable range label, e.g. "Ayah 1–10".
  String get rangeLabel {
    if (ayat.isEmpty) return '(empty)';
    return 'Ayah ${ayat.first.number}–${ayat.last.number}';
  }
}

/// Slices surah ayat into page-sized chunks of up to [chunkSize] ayat each.
///
/// The last chunk may be shorter if the total doesn't divide evenly.
/// Returns at least one chunk (possibly empty if the surah has no ayat).
List<MemorizationChunk> buildChunks(
  List<Ayah> surahAyat, {
  int chunkSize = 10,
}) {
  if (surahAyat.isEmpty) {
    return [const MemorizationChunk(index: 0, ayat: [])];
  }

  final chunks = <MemorizationChunk>[];
  for (int i = 0; i < surahAyat.length; i += chunkSize) {
    final end = (i + chunkSize > surahAyat.length)
        ? surahAyat.length
        : i + chunkSize;
    chunks.add(
      MemorizationChunk(index: chunks.length, ayat: surahAyat.sublist(i, end)),
    );
  }
  return chunks;
}

/// Splits a list of Ayahs into 3 sections as equally as possible.
///
/// For example:
///   10 ayat → [4, 3, 3]
///   11 ayat → [4, 4, 3]
///   12 ayat → [4, 4, 4]
///    7 ayat → [3, 2, 2]
///    4 ayat → [2, 1, 1]
///    3 ayat → [1, 1, 1]
///    2 ayat → [1, 1, 0] — section 3 will be empty
///    1 ayah → [1, 0, 0] — sections 2 & 3 will be empty
///
/// Returns exactly 3 sub-lists (some may be empty for very short chunks).
List<List<Ayah>> splitIntoThreeSections(List<Ayah> ayat) {
  final total = ayat.length;
  if (total == 0) return [[], [], []];

  final base = total ~/ 3;
  final remainder = total % 3;

  // Distribute the remainder to the first sections.
  final sizes = [
    base + (remainder > 0 ? 1 : 0),
    base + (remainder > 1 ? 1 : 0),
    base,
  ];

  int offset = 0;
  return sizes.map((size) {
    final section = ayat.sublist(offset, offset + size);
    offset += size;
    return section;
  }).toList();
}
