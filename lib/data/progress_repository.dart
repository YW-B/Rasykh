import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

/// The user's last working position in a Mutasawi session.
class LastPosition {
  final int surahNumber;
  final int chunkIndex;
  final int ayahNumber;

  const LastPosition({
    required this.surahNumber,
    required this.chunkIndex,
    required this.ayahNumber,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'chunkIndex': chunkIndex,
    'ayahNumber': ayahNumber,
  };

  factory LastPosition.fromJson(Map<String, dynamic> j) => LastPosition(
    surahNumber: j['surahNumber'] as int,
    chunkIndex: j['chunkIndex'] as int,
    ayahNumber: j['ayahNumber'] as int,
  );

  @override
  String toString() =>
      'LastPosition(surah=$surahNumber, chunk=$chunkIndex, ayah=$ayahNumber)';
}

/// Completion state for a single chunk inside a surah, including drill state.
class ChunkProgress {
  final int surahNumber;
  final int chunkIndex;
  final int ayatCount;
  final bool completedMemorization;
  final bool completedRecall;
  final int lastAyahNumberInsideChunk; // 1-based ayah number in this surah
  final int completedSections; // 0, 1, 2, or 3
  final int ease; // 100–300, default 250 (SM-2 style)
  final int intervalDays; // current interval in days
  final DateTime? dueDate; // next scheduled recall date

  const ChunkProgress({
    required this.surahNumber,
    required this.chunkIndex,
    required this.ayatCount,
    this.completedMemorization = false,
    this.completedRecall = false,
    this.lastAyahNumberInsideChunk = 0,
    this.completedSections = 0,
    this.ease = 250,
    this.intervalDays = 0,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'chunkIndex': chunkIndex,
    'ayatCount': ayatCount,
    'completedMemorization': completedMemorization,
    'completedRecall': completedRecall,
    'lastAyahNumberInsideChunk': lastAyahNumberInsideChunk,
    'completedSections': completedSections,
    'ease': ease,
    'intervalDays': intervalDays,
    'dueDate': dueDate?.toIso8601String(),
  };

  factory ChunkProgress.fromJson(Map<String, dynamic> j) => ChunkProgress(
    surahNumber: j['surahNumber'] as int,
    chunkIndex: j['chunkIndex'] as int,
    ayatCount: j['ayatCount'] as int,
    completedMemorization: j['completedMemorization'] as bool? ?? false,
    completedRecall: j['completedRecall'] as bool? ?? false,
    lastAyahNumberInsideChunk: j['lastAyahNumberInsideChunk'] as int? ?? 0,
    completedSections: j['completedSections'] as int? ?? 0,
    ease: j['ease'] as int? ?? 250,
    intervalDays: j['intervalDays'] as int? ?? 0,
    dueDate: j['dueDate'] != null
        ? DateTime.tryParse(j['dueDate'] as String)
        : null,
  );

  String get key => '$surahNumber:$chunkIndex';
}

/// Aggregated progress for a single surah.
class SurahProgress {
  final int surahNumber;
  final int totalAyatMemorized;
  final int chunksCompleted;

  const SurahProgress({
    required this.surahNumber,
    this.totalAyatMemorized = 0,
    this.chunksCompleted = 0,
  });
}

/// Global memorization statistics.
class ProgressStats {
  final int totalAyatMemorized;
  final int streakDays;
  final DateTime? lastActiveDate;

  const ProgressStats({
    this.totalAyatMemorized = 0,
    this.streakDays = 0,
    this.lastActiveDate,
  });
}

// ---------------------------------------------------------------------------
// SharedPreferences keys
// ---------------------------------------------------------------------------
class _K {
  static const lastPosition = 'last_position_json';
  static const chunkMap = 'chunk_progress_map_json';
  static const totalAyat = 'total_ayat_memorized';
  static const streakDays = 'streak_days';
  static const lastActiveDate = 'last_active_date';
  static const requireRecallForStats = 'require_recall_for_stats';
  static const dailyTargetAyat = 'daily_target_ayat';
}

// ---------------------------------------------------------------------------
// ProgressController
// ---------------------------------------------------------------------------

class ProgressController extends ChangeNotifier {
  static final ProgressController _instance = ProgressController._();
  factory ProgressController() => _instance;
  ProgressController._();

  late SharedPreferences _prefs;
  bool _loaded = false;

  // Cached state
  LastPosition? lastPosition;
  final Map<String, ChunkProgress> _chunks = {};
  int totalAyatMemorized = 0;
  int streakDays = 0;
  DateTime? lastActiveDate;

  // Settings
  bool requireRecallForStats = false;
  int dailyTargetAyat = 10;

  bool get hasLastPosition => lastPosition != null;

  /// Call once at app startup.
  Future<void> init() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    _readAll();
    _loaded = true;
    debugPrint('[Progress] init complete:');
    debugPrint('[Progress]   lastPosition = $lastPosition');
    debugPrint('[Progress]   totalAyatMemorized = $totalAyatMemorized');
    debugPrint('[Progress]   streakDays = $streakDays');
    debugPrint('[Progress]   chunks loaded = ${_chunks.length}');
    for (final c in _chunks.values) {
      debugPrint(
        '[Progress]     ${c.key} → ayat=${c.ayatCount} '
        'sections=${c.completedSections} '
        'lastAyah=${c.lastAyahNumberInsideChunk} '
        'done=${c.completedMemorization}',
      );
    }
  }

  void _readAll() {
    final posJson = _prefs.getString(_K.lastPosition);
    if (posJson != null) {
      try {
        lastPosition = LastPosition.fromJson(
          json.decode(posJson) as Map<String, dynamic>,
        );
      } catch (e) {
        debugPrint('[Progress] Failed to parse lastPosition, skipping: $e');
        lastPosition = null;
      }
    }

    final mapJson = _prefs.getString(_K.chunkMap);
    if (mapJson != null) {
      try {
        final decoded = json.decode(mapJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _chunks[entry.key] = ChunkProgress.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      } catch (e) {
        debugPrint('[Progress] Failed to parse chunkMap, skipping: $e');
        _chunks.clear();
      }
    }

    totalAyatMemorized = _prefs.getInt(_K.totalAyat) ?? 0;
    streakDays = _prefs.getInt(_K.streakDays) ?? 0;
    final dateStr = _prefs.getString(_K.lastActiveDate);
    if (dateStr != null) {
      lastActiveDate = DateTime.tryParse(dateStr);
    }
    requireRecallForStats = _prefs.getBool(_K.requireRecallForStats) ?? false;
    dailyTargetAyat = _prefs.getInt(_K.dailyTargetAyat) ?? 10;
  }

  // ---------- Public API ----------

  /// Save the user's current working position.
  Future<void> saveLastPosition(LastPosition pos) async {
    lastPosition = pos;
    await _prefs.setString(_K.lastPosition, json.encode(pos.toJson()));
    debugPrint('[Progress] saveLastPosition → $pos');
    notifyListeners();
  }

  /// Load last position (also available via the cached [lastPosition] field).
  LastPosition? loadLastPosition() => lastPosition;

  /// Load saved drill state for a specific chunk.
  ChunkProgress? loadChunkProgress(int surahNumber, int chunkIndex) {
    final key = '$surahNumber:$chunkIndex';
    return _chunks[key];
  }

  /// Persist the current drill state for a chunk (called on every rep).
  Future<void> saveChunkProgress(ChunkProgress progress) async {
    _chunks[progress.key] = progress;
    await _saveChunkMap();
    debugPrint(
      '[Progress] saveChunkProgress → ${progress.key} '
      'lastAyah=${progress.lastAyahNumberInsideChunk} '
      'sections=${progress.completedSections} '
      'done=${progress.completedMemorization}',
    );
    notifyListeners();
  }

  /// Called when the user completes "Link All 3 Sections" for a chunk.
  ///
  /// Guards against double-counting: if the chunk is already marked complete,
  /// the global total is NOT incremented again.
  Future<void> markChunkCompleted({
    required int surahNumber,
    required int chunkIndex,
    required int ayatCount,
    required int lastAyahNumber,
    int? nextChunkFirstAyah,
    int? nextChunkIndex,
  }) async {
    debugPrint(
      '[Progress] markChunkCompleted → surah=$surahNumber '
      'chunk=$chunkIndex ayat=$ayatCount lastAyah=$lastAyahNumber',
    );

    final key = '$surahNumber:$chunkIndex';
    final alreadyDone = _chunks[key]?.completedMemorization ?? false;

    final prevEase = _chunks[key]?.ease ?? 250;
    final prevInterval = _chunks[key]?.intervalDays ?? 0;
    final prevDue = _chunks[key]?.dueDate;

    _chunks[key] = ChunkProgress(
      surahNumber: surahNumber,
      chunkIndex: chunkIndex,
      ayatCount: ayatCount,
      completedMemorization: true,
      lastAyahNumberInsideChunk: lastAyahNumber,
      completedSections: 3,
      ease: prevEase,
      intervalDays: prevInterval,
      dueDate: prevDue,
    );
    await _saveChunkMap();

    if (!alreadyDone) {
      totalAyatMemorized += ayatCount;
      await _prefs.setInt(_K.totalAyat, totalAyatMemorized);
      debugPrint('[Progress]   new totalAyatMemorized = $totalAyatMemorized');

      // Initialize recall: first review tomorrow.
      final today = _todayDate();
      final existing = _chunks[key]!;
      _chunks[key] = ChunkProgress(
        surahNumber: existing.surahNumber,
        chunkIndex: existing.chunkIndex,
        ayatCount: existing.ayatCount,
        completedMemorization: existing.completedMemorization,
        completedRecall: existing.completedRecall,
        lastAyahNumberInsideChunk: existing.lastAyahNumberInsideChunk,
        completedSections: existing.completedSections,
        ease: existing.ease,
        intervalDays: 1,
        dueDate: today.add(const Duration(days: 1)),
      );
      await _saveChunkMap();
    } else {
      debugPrint(
        '[Progress]   chunk already completed, skipping total increment',
      );
    }

    await _updateStreak();

    // Advance last position to next chunk or keep as-is.
    if (nextChunkIndex != null && nextChunkFirstAyah != null) {
      final nextPos = LastPosition(
        surahNumber: surahNumber,
        chunkIndex: nextChunkIndex,
        ayahNumber: nextChunkFirstAyah,
      );
      await saveLastPosition(nextPos);
      debugPrint('[Progress]   advanced lastPosition → $nextPos');
    } else {
      debugPrint('[Progress]   no next chunk, keeping lastPosition as-is');
    }

    notifyListeners();
  }

  /// Returns per-surah progress for every surah that has at least one
  /// completed chunk.
  ///
  /// If [requireRecallForStats] is true, only chunks with both
  /// memorization AND recall completed are counted.
  Map<int, SurahProgress> loadAllSurahProgress() {
    final map = <int, SurahProgress>{};
    for (final cp in _chunks.values) {
      if (!cp.completedMemorization) continue;
      if (requireRecallForStats && !cp.completedRecall) continue;
      final existing = map[cp.surahNumber];
      map[cp.surahNumber] = SurahProgress(
        surahNumber: cp.surahNumber,
        totalAyatMemorized: (existing?.totalAyatMemorized ?? 0) + cp.ayatCount,
        chunksCompleted: (existing?.chunksCompleted ?? 0) + 1,
      );
    }
    return map;
  }

  /// Returns chunks where memorization is done and recall is DUE today
  /// (or overdue). Sorted by oldest due first, limited to [limit].
  /// Falls back to chunks with no dueDate (never scheduled) for backwards
  /// compatibility.
  List<ChunkProgress> chunksNeedingRecall({int limit = 3}) {
    final today = _todayDate();
    final due = <ChunkProgress>[];

    for (final cp in _chunks.values) {
      if (!cp.completedMemorization) continue;
      // Include if due today/overdue, OR if never scheduled (legacy data).
      if (cp.dueDate == null) {
        due.add(cp);
      } else if (!cp.dueDate!.isAfter(today)) {
        due.add(cp);
      }
    }

    due.sort(
      (a, b) =>
          (a.dueDate ?? DateTime(2000)).compareTo(b.dueDate ?? DateTime(2000)),
    );

    return due.length > limit ? due.sublist(0, limit) : due;
  }

  /// Update the requireRecallForStats setting.
  Future<void> setRequireRecallForStats(bool value) async {
    requireRecallForStats = value;
    await _prefs.setBool(_K.requireRecallForStats, value);
    notifyListeners();
  }

  /// Update the daily target ayat setting.
  Future<void> setDailyTargetAyat(int value) async {
    dailyTargetAyat = value;
    await _prefs.setInt(_K.dailyTargetAyat, value);
    notifyListeners();
  }

  /// Returns global stats.
  ProgressStats loadStats() => ProgressStats(
    totalAyatMemorized: totalAyatMemorized,
    streakDays: streakDays,
    lastActiveDate: lastActiveDate,
  );

  /// Check if a specific chunk has been completed.
  bool isChunkCompleted(int surahNumber, int chunkIndex) {
    final key = '$surahNumber:$chunkIndex';
    return _chunks[key]?.completedMemorization ?? false;
  }

  /// Check if recall has been completed for a specific chunk.
  bool isRecallCompleted(int surahNumber, int chunkIndex) {
    final key = '$surahNumber:$chunkIndex';
    return _chunks[key]?.completedRecall ?? false;
  }

  /// Mark the recall challenge as completed for a chunk.
  Future<void> markRecallCompleted(int surahNumber, int chunkIndex) async {
    final key = '$surahNumber:$chunkIndex';
    final existing = _chunks[key];
    _chunks[key] = ChunkProgress(
      surahNumber: surahNumber,
      chunkIndex: chunkIndex,
      ayatCount: existing?.ayatCount ?? 0,
      completedMemorization: existing?.completedMemorization ?? false,
      completedRecall: true,
      lastAyahNumberInsideChunk: existing?.lastAyahNumberInsideChunk ?? 0,
      completedSections: existing?.completedSections ?? 0,
      ease: existing?.ease ?? 250,
      intervalDays: existing?.intervalDays ?? 0,
      dueDate: existing?.dueDate,
    );
    await _saveChunkMap();
    debugPrint(
      '[Progress] markRecallCompleted → surah=$surahNumber chunk=$chunkIndex',
    );
    notifyListeners();
  }

  /// Advance the spaced-repetition schedule for a chunk after recall.
  Future<void> scheduleRecall({
    required int surahNumber,
    required int chunkIndex,
    required bool wasEasy,
  }) async {
    final key = '$surahNumber:$chunkIndex';
    final existing = _chunks[key];
    if (existing == null) return;

    final today = _todayDate();
    var ease = existing.ease;
    var interval = existing.intervalDays;

    if (wasEasy) {
      ease = (ease + 20).clamp(130, 300);
      interval = interval == 0 ? 1 : (interval * 1.8).round().clamp(1, 60);
    } else {
      ease = (ease - 30).clamp(130, 300);
      interval = 1;
    }

    _chunks[key] = ChunkProgress(
      surahNumber: existing.surahNumber,
      chunkIndex: existing.chunkIndex,
      ayatCount: existing.ayatCount,
      completedMemorization: existing.completedMemorization,
      completedRecall: existing.completedRecall,
      lastAyahNumberInsideChunk: existing.lastAyahNumberInsideChunk,
      completedSections: existing.completedSections,
      ease: ease,
      intervalDays: interval,
      dueDate: today.add(Duration(days: interval)),
    );
    await _saveChunkMap();
    debugPrint(
      '[Progress] scheduleRecall → $key ease=$ease interval=$interval '
      'nextDue=${today.add(Duration(days: interval))}',
    );
    notifyListeners();
  }

  // ---------- Internal helpers ----------

  Future<void> _saveChunkMap() async {
    final encoded = <String, dynamic>{};
    for (final entry in _chunks.entries) {
      encoded[entry.key] = entry.value.toJson();
    }
    await _prefs.setString(_K.chunkMap, json.encode(encoded));
  }

  Future<void> _updateStreak() async {
    final today = _todayDate();
    if (lastActiveDate != null) {
      final diff = today.difference(lastActiveDate!).inDays;
      if (diff == 0) return;
      if (diff == 1) {
        streakDays += 1;
      } else {
        streakDays = 1;
      }
    } else {
      streakDays = 1;
    }
    lastActiveDate = today;
    await _prefs.setInt(_K.streakDays, streakDays);
    await _prefs.setString(_K.lastActiveDate, today.toIso8601String());
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
