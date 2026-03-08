import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen ambient background with gradient, floating orbs, and particles.
/// Matches the React `AmbientBackground` component.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbController;

  // Pre-computed particle data (fixed seed → deterministic)
  static const int _particleCount = 20;
  late final List<_ParticleData> _particleConfigs;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Pre-generate particle configs once
    final rng = Random(42);
    _particleConfigs = List.generate(_particleCount, (_) {
      return _ParticleData(
        leftFraction: rng.nextDouble(),
        size: rng.nextDouble() * 4 + 2,
        durationSeconds: (rng.nextDouble() * 20 + 15).toInt(),
        delaySeconds: (rng.nextDouble() * 20).toInt(),
      );
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.deepEmerald,
              AppColors.darkerEmerald,
              AppColors.slateBlue,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            final val = _orbController.value;
            return Stack(
              children: [
                // --- Gradient Orb 1 (top-left) ---
                Positioned(
                  top: -size.height * 0.10 + 15.0 * val,
                  left: -size.width * 0.10 + (-20.0 * val),
                  child: Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald500.withValues(alpha: 0.10),
                    ),
                  ),
                ),

                // --- Gradient Orb 2 (bottom-right) ---
                Positioned(
                  bottom: -size.height * 0.10 + (-15.0 * (1 - val)),
                  right: -size.width * 0.10 + (20.0 * (1 - val)),
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald600.withValues(alpha: 0.10),
                    ),
                  ),
                ),

                // --- Particle Field (stable widget list) ---
                child!,
              ],
            );
          },
          // child is built once and reused across animation frames
          child: Stack(
            children: [
              for (int i = 0; i < _particleCount; i++)
                _Particle(
                  key: ValueKey('particle_$i'),
                  config: _particleConfigs[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Immutable data bag for one particle (no widget rebuilds needed).
class _ParticleData {
  final double leftFraction; // 0..1, multiplied by screen width at paint time
  final double size;
  final int durationSeconds;
  final int delaySeconds;

  const _ParticleData({
    required this.leftFraction,
    required this.size,
    required this.durationSeconds,
    required this.delaySeconds,
  });
}

/// A single animated particle that floats upward.
class _Particle extends StatefulWidget {
  final _ParticleData config;

  const _Particle({super.key, required this.config});

  @override
  State<_Particle> createState() => _ParticleState();
}

class _ParticleState extends State<_Particle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.config.durationSeconds),
    );

    // Stagger start via delay, then loop forever.
    if (widget.config.delaySeconds > 0) {
      Future.delayed(Duration(seconds: widget.config.delaySeconds), () {
        if (mounted) {
          _controller.repeat();
        }
      });
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseLeft = widget.config.leftFraction * screenSize.width;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Opacity: 0 → 0.5 at 20%, hold, → 0 at 80%
        double opacity;
        if (t < 0.2) {
          opacity = (t / 0.2) * 0.5;
        } else if (t < 0.8) {
          opacity = 0.5;
        } else {
          opacity = (1 - (t - 0.8) / 0.2) * 0.5;
        }

        // Move from bottom off-screen upward past the top
        final totalTravel = screenSize.height * 1.2;
        final top = screenSize.height - t * totalTravel;
        final dx = t * 50;

        return Positioned(
          left: baseLeft + dx,
          top: top,
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
        );
      },
      // Static child — never rebuilt
      child: Container(
        width: widget.config.size,
        height: widget.config.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.emerald400,
        ),
      ),
    );
  }
}
