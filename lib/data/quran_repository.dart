import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'mock_data.dart';
export 'mock_data.dart' show Surah, Ayah;

/// Offline-first Quran data repository.
///
/// Loads Uthmani text from a local asset JSON bundled with the app.
/// No HTTP, AI, or external API calls — fully offline.
class QuranRepository {
  // Singleton
  static final QuranRepository _instance = QuranRepository._();
  factory QuranRepository() => _instance;
  QuranRepository._();

  List<Surah> _surahs = [];
  bool _loaded = false;

  // ---------- Surah metadata (not in Tanzil JSON) ----------
  // Maps surah number → (Arabic-transliterated name, English name, type).
  static const Map<int, (String, String, String)> _surahMeta = {
    1: ('Al-Fatiha', 'The Opening', 'Meccan'),
    2: ('Al-Baqarah', 'The Cow', 'Medinan'),
    3: ('Aal-E-Imran', 'The Family of Imran', 'Medinan'),
    4: ('An-Nisa', 'The Women', 'Medinan'),
    5: ('Al-Maidah', 'The Table Spread', 'Medinan'),
    6: ('Al-Anam', 'The Cattle', 'Meccan'),
    7: ('Al-Araf', 'The Heights', 'Meccan'),
    8: ('Al-Anfal', 'The Spoils of War', 'Medinan'),
    9: ('At-Tawbah', 'The Repentance', 'Medinan'),
    10: ('Yunus', 'Jonah', 'Meccan'),
    11: ('Hud', 'Hud', 'Meccan'),
    12: ('Yusuf', 'Joseph', 'Meccan'),
    13: ('Ar-Rad', 'The Thunder', 'Medinan'),
    14: ('Ibrahim', 'Abraham', 'Meccan'),
    15: ('Al-Hijr', 'The Rocky Tract', 'Meccan'),
    16: ('An-Nahl', 'The Bee', 'Meccan'),
    17: ('Al-Isra', 'The Night Journey', 'Meccan'),
    18: ('Al-Kahf', 'The Cave', 'Meccan'),
    19: ('Maryam', 'Mary', 'Meccan'),
    20: ('Ta-Ha', 'Ta-Ha', 'Meccan'),
    21: ('Al-Anbiya', 'The Prophets', 'Meccan'),
    22: ('Al-Hajj', 'The Pilgrimage', 'Medinan'),
    23: ('Al-Muminun', 'The Believers', 'Meccan'),
    24: ('An-Nur', 'The Light', 'Medinan'),
    25: ('Al-Furqan', 'The Criterion', 'Meccan'),
    26: ('Ash-Shuara', 'The Poets', 'Meccan'),
    27: ('An-Naml', 'The Ants', 'Meccan'),
    28: ('Al-Qasas', 'The Stories', 'Meccan'),
    29: ('Al-Ankabut', 'The Spider', 'Meccan'),
    30: ('Ar-Rum', 'The Romans', 'Meccan'),
    31: ('Luqman', 'Luqman', 'Meccan'),
    32: ('As-Sajdah', 'The Prostration', 'Meccan'),
    33: ('Al-Ahzab', 'The Combined Forces', 'Medinan'),
    34: ('Saba', 'Sheba', 'Meccan'),
    35: ('Fatir', 'Originator', 'Meccan'),
    36: ('Ya-Sin', 'Ya-Sin', 'Meccan'),
    37: ('As-Saffat', 'Those Who Set The Ranks', 'Meccan'),
    38: ('Sad', 'Sad', 'Meccan'),
    39: ('Az-Zumar', 'The Troops', 'Meccan'),
    40: ('Ghafir', 'The Forgiver', 'Meccan'),
    41: ('Fussilat', 'Explained in Detail', 'Meccan'),
    42: ('Ash-Shura', 'The Consultation', 'Meccan'),
    43: ('Az-Zukhruf', 'The Ornaments of Gold', 'Meccan'),
    44: ('Ad-Dukhan', 'The Smoke', 'Meccan'),
    45: ('Al-Jathiyah', 'The Crouching', 'Meccan'),
    46: ('Al-Ahqaf', 'The Wind-Curved Sandhills', 'Meccan'),
    47: ('Muhammad', 'Muhammad', 'Medinan'),
    48: ('Al-Fath', 'The Victory', 'Medinan'),
    49: ('Al-Hujurat', 'The Rooms', 'Medinan'),
    50: ('Qaf', 'Qaf', 'Meccan'),
    51: ('Adh-Dhariyat', 'The Winnowing Winds', 'Meccan'),
    52: ('At-Tur', 'The Mount', 'Meccan'),
    53: ('An-Najm', 'The Star', 'Meccan'),
    54: ('Al-Qamar', 'The Moon', 'Meccan'),
    55: ('Ar-Rahman', 'The Beneficent', 'Medinan'),
    56: ('Al-Waqiah', 'The Inevitable', 'Meccan'),
    57: ('Al-Hadid', 'The Iron', 'Medinan'),
    58: ('Al-Mujadila', 'The Pleading Woman', 'Medinan'),
    59: ('Al-Hashr', 'The Exile', 'Medinan'),
    60: ('Al-Mumtahanah', 'She That is to be Examined', 'Medinan'),
    61: ('As-Saff', 'The Ranks', 'Medinan'),
    62: ('Al-Jumuah', 'The Congregation', 'Medinan'),
    63: ('Al-Munafiqun', 'The Hypocrites', 'Medinan'),
    64: ('At-Taghabun', 'The Mutual Disillusion', 'Medinan'),
    65: ('At-Talaq', 'The Divorce', 'Medinan'),
    66: ('At-Tahrim', 'The Prohibition', 'Medinan'),
    67: ('Al-Mulk', 'The Sovereignty', 'Meccan'),
    68: ('Al-Qalam', 'The Pen', 'Meccan'),
    69: ('Al-Haqqah', 'The Reality', 'Meccan'),
    70: ('Al-Maarij', 'The Ascending Stairways', 'Meccan'),
    71: ('Nuh', 'Noah', 'Meccan'),
    72: ('Al-Jinn', 'The Jinn', 'Meccan'),
    73: ('Al-Muzzammil', 'The Enshrouded One', 'Meccan'),
    74: ('Al-Muddaththir', 'The Cloaked One', 'Meccan'),
    75: ('Al-Qiyamah', 'The Resurrection', 'Meccan'),
    76: ('Al-Insan', 'The Human', 'Medinan'),
    77: ('Al-Mursalat', 'The Emissaries', 'Meccan'),
    78: ('An-Naba', 'The Tidings', 'Meccan'),
    79: ('An-Naziat', 'Those Who Drag Forth', 'Meccan'),
    80: ('Abasa', 'He Frowned', 'Meccan'),
    81: ('At-Takwir', 'The Overthrowing', 'Meccan'),
    82: ('Al-Infitar', 'The Cleaving', 'Meccan'),
    83: ('Al-Mutaffifin', 'The Defrauding', 'Meccan'),
    84: ('Al-Inshiqaq', 'The Splitting Open', 'Meccan'),
    85: ('Al-Buruj', 'The Mansions of the Stars', 'Meccan'),
    86: ('At-Tariq', 'The Morning Star', 'Meccan'),
    87: ('Al-Ala', 'The Most High', 'Meccan'),
    88: ('Al-Ghashiyah', 'The Overwhelming', 'Meccan'),
    89: ('Al-Fajr', 'The Dawn', 'Meccan'),
    90: ('Al-Balad', 'The City', 'Meccan'),
    91: ('Ash-Shams', 'The Sun', 'Meccan'),
    92: ('Al-Layl', 'The Night', 'Meccan'),
    93: ('Ad-Duha', 'The Morning Hours', 'Meccan'),
    94: ('Ash-Sharh', 'The Relief', 'Meccan'),
    95: ('At-Tin', 'The Fig', 'Meccan'),
    96: ('Al-Alaq', 'The Clot', 'Meccan'),
    97: ('Al-Qadr', 'The Power', 'Meccan'),
    98: ('Al-Bayyinah', 'The Clear Proof', 'Medinan'),
    99: ('Az-Zalzalah', 'The Earthquake', 'Medinan'),
    100: ('Al-Adiyat', 'The Coursers', 'Meccan'),
    101: ('Al-Qariah', 'The Calamity', 'Meccan'),
    102: ('At-Takathur', 'The Rivalry in World Increase', 'Meccan'),
    103: ('Al-Asr', 'The Declining Day', 'Meccan'),
    104: ('Al-Humazah', 'The Traducer', 'Meccan'),
    105: ('Al-Fil', 'The Elephant', 'Meccan'),
    106: ('Quraysh', 'Quraysh', 'Meccan'),
    107: ('Al-Maun', 'The Small Kindnesses', 'Meccan'),
    108: ('Al-Kawthar', 'The Abundance', 'Meccan'),
    109: ('Al-Kafirun', 'The Disbelievers', 'Meccan'),
    110: ('An-Nasr', 'The Divine Support', 'Medinan'),
    111: ('Al-Masad', 'The Palm Fiber', 'Meccan'),
    112: ('Al-Ikhlas', 'The Sincerity', 'Meccan'),
    113: ('Al-Falaq', 'The Daybreak', 'Meccan'),
    114: ('An-Nas', 'Mankind', 'Meccan'),
  };

  // ---------- initialization ----------

  /// Call once at app startup (e.g. in main()).
  /// Loads the Tanzil Uthmani JSON from the bundled asset.
  Future<void> init() async {
    if (_loaded) return;

    final jsonStr = await rootBundle.loadString(
      'assets/quran/quran_uthmani.json',
    );
    final Map<String, dynamic> root = json.decode(jsonStr);
    final List<dynamic> surahsList = root['surahs'] as List<dynamic>;

    _surahs = surahsList.map((s) {
      final int num = s['number'] as int;
      final meta = _surahMeta[num] ?? ('Surah $num', 'Surah $num', 'Meccan');
      final List<dynamic> ayahsList = s['ayahs'] as List<dynamic>;

      final ayat = ayahsList.map((a) {
        return Ayah(
          number: a['number'] as int,
          arabic: a['text'] as String,
          english: '', // No translation in Tanzil Uthmani — add later
        );
      }).toList();

      return Surah(
        number: num,
        name: meta.$1,
        english: meta.$2,
        verses: ayat.length,
        type: meta.$3,
        ayat: ayat,
      );
    }).toList();

    _loaded = true;
  }

  /// Whether [init] has completed.
  bool get isLoaded => _loaded;

  // ---------- public API ----------

  /// Returns every surah available in the dataset.
  List<Surah> getAllSurahs() => List.unmodifiable(_surahs);

  /// Returns the surah with the given [number], or `null` if not found.
  Surah? getSurah(int number) {
    // Surah numbers are 1-indexed and ordered, so fast lookup:
    if (number >= 1 && number <= _surahs.length) {
      final s = _surahs[number - 1];
      if (s.number == number) return s;
    }
    // Fallback linear search
    try {
      return _surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  /// Returns all ayat for the surah with the given [surahNumber].
  /// Returns an empty list if the surah is not found.
  List<Ayah> getSurahAyat(int surahNumber) {
    return getSurah(surahNumber)?.ayat ?? [];
  }

  /// Returns a single ayah, or `null` if not found.
  Ayah? getAyah(int surahNumber, int ayahNumber) {
    final ayat = getSurahAyat(surahNumber);
    if (ayahNumber >= 1 && ayahNumber <= ayat.length) {
      final a = ayat[ayahNumber - 1];
      if (a.number == ayahNumber) return a;
    }
    try {
      return ayat.firstWhere((a) => a.number == ayahNumber);
    } catch (_) {
      return null;
    }
  }

  /// Total number of surahs currently loaded.
  int get surahCount => _surahs.length;
}
