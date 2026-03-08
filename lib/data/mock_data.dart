/// Model for a single Ayah within a Surah.
class Ayah {
  final int number;
  final String arabic;
  final String english;

  const Ayah({
    required this.number,
    required this.arabic,
    required this.english,
  });
}

/// Model for a Surah entry shown in the Library.
class Surah {
  final int number;
  final String name;
  final String english;
  final int verses;
  final String type; // "Meccan" or "Medinan"
  final List<Ayah> ayat;

  const Surah({
    required this.number,
    required this.name,
    required this.english,
    required this.verses,
    required this.type,
    required this.ayat,
  });
}

// ---------------------------------------------------------------------------
// Helper: generate N placeholder Ayahs.
// ---------------------------------------------------------------------------
List<Ayah> _placeholderAyat(int count) {
  const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  String toArabicDigits(int n) {
    return n
        .toString()
        .split('')
        .map((d) => arabicNumerals[int.parse(d)])
        .join();
  }

  return List.generate(count, (i) {
    final num = i + 1;
    return Ayah(
      number: num,
      arabic: 'آية ${toArabicDigits(num)}',
      english: 'Placeholder translation for ayah $num.',
    );
  });
}

// ---------------------------------------------------------------------------
// Static mock data — placeholder Arabic only.
// Real Quran text will come from Tanzil Uthmani later.
// ---------------------------------------------------------------------------

final List<Surah> kSurahs = [
  Surah(
    number: 1,
    name: "Al-Fatiha",
    english: "The Opening",
    verses: 7,
    type: "Meccan",
    ayat: _placeholderAyat(7),
  ),
  Surah(
    number: 18,
    name: "Al-Kahf",
    english: "The Cave",
    verses: 12,
    type: "Meccan",
    ayat: _placeholderAyat(12),
  ),
  Surah(
    number: 36,
    name: "Ya-Sin",
    english: "Ya-Sin",
    verses: 10,
    type: "Meccan",
    ayat: _placeholderAyat(10),
  ),
  Surah(
    number: 55,
    name: "Ar-Rahman",
    english: "The Beneficent",
    verses: 11,
    type: "Medinan",
    ayat: _placeholderAyat(11),
  ),
  Surah(
    number: 67,
    name: "Al-Mulk",
    english: "The Sovereignty",
    verses: 10,
    type: "Meccan",
    ayat: _placeholderAyat(10),
  ),
  Surah(
    number: 112,
    name: "Al-Ikhlas",
    english: "The Sincerity",
    verses: 4,
    type: "Meccan",
    ayat: _placeholderAyat(4),
  ),
];
