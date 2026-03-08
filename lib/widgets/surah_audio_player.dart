import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class SurahAudioPlayer extends StatefulWidget {
  final int surahNumber;

  const SurahAudioPlayer({super.key, required this.surahNumber});

  @override
  State<SurahAudioPlayer> createState() => _SurahAudioPlayerState();
}

class _SurahAudioPlayerState extends State<SurahAudioPlayer> {
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioService.instance.player;
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing =
            state?.playing == true &&
            state?.processingState != ProcessingState.completed;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;
            final max = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 0.0;

            Future<void> seekRelative(int seconds) async {
              final current = _player.position;
              final target = current + Duration(seconds: seconds);
              final clamped = target < Duration.zero
                  ? Duration.zero
                  : (duration > Duration.zero && target > duration
                        ? duration
                        : target);
              await _player.seek(clamped);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // 5 seconds back
                    IconButton(
                      icon: const Icon(Icons.replay_5),
                      color: AppColors.emerald100.withValues(alpha: 0.9),
                      onPressed: max > 0 ? () => seekRelative(-5) : null,
                    ),
                    const SizedBox(width: 4),
                    // Play / Pause
                    GestureDetector(
                      onTap: () async {
                        if (playing) {
                          await AudioService.instance.pause();
                        } else {
                          await AudioService.instance.playSurah(
                            widget.surahNumber,
                          );
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.emerald500,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // 5 seconds forward
                    IconButton(
                      icon: const Icon(Icons.forward_5),
                      color: AppColors.emerald100.withValues(alpha: 0.9),
                      onPressed: max > 0 ? () => seekRelative(5) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\u0627\u0633\u062a\u0645\u0639 \u0644\u0644\u0633\u0648\u0631\u0629 \u0643\u0627\u0645\u0644\u0629',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.scheherazadeNew(
                          color: AppColors.emerald100.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (max > 0)
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: position.inMilliseconds
                              .clamp(0, max.toInt())
                              .toDouble(),
                          max: max,
                          onChanged: (v) async {
                            await _player.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _format(position),
                            style: GoogleFonts.inter(
                              color: AppColors.emerald100.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _format(duration),
                            style: GoogleFonts.inter(
                              color: AppColors.emerald100.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
