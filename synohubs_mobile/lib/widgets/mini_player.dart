import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/audio_service.dart';

/// Persistent mini audio player bar.
/// Renders at the bottom of MainShell so music continues across all tabs.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService.instance,
      builder: (context, _) {
        final audio = AudioService.instance;
        if (!audio.hasTrack) return const SizedBox.shrink();

        final track = audio.currentTrack!;
        final progressPct = audio.duration.inMilliseconds > 0
            ? audio.currentTime.inMilliseconds / audio.duration.inMilliseconds
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar (thin line above the player)
            LinearProgressIndicator(
              value: progressPct.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Player bar
            Container(
              color: AppColors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // ── Album art / icon ──
                  _buildCoverArt(audio.isPlaying),
                  const SizedBox(width: 10),

                  // ── Track info ──
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showQueueSheet(context),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            track.artist,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Time ──
                  Text(
                    '${audio.formatDuration(audio.currentTime)} / ${audio.formatDuration(audio.duration)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Controls ──
                  _ControlButton(
                    icon: Icons.skip_previous,
                    size: 22,
                    onTap: audio.prevTrack,
                  ),
                  const SizedBox(width: 2),
                  _PlayPauseButton(isPlaying: audio.isPlaying),
                  const SizedBox(width: 2),
                  _ControlButton(
                    icon: Icons.skip_next,
                    size: 22,
                    onTap: audio.nextTrack,
                  ),
                  const SizedBox(width: 4),

                  // ── Close ──
                  _ControlButton(
                    icon: Icons.close,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                    onTap: audio.stop,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoverArt(bool isPlaying) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primaryContainer.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 20,
            color: isPlaying ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          if (isPlaying)
            Positioned(
              bottom: 4,
              child: _MiniEqualizer(),
            ),
        ],
      ),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _QueueSheet(),
    );
  }
}

// ── Play/Pause Button ──────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  const _PlayPauseButton({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: AudioService.instance.togglePlay,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: AppColors.onPrimary,
          size: 20,
        ),
      ),
    );
  }
}

// ── Control Button ─────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: size,
          color: color ?? AppColors.onSurface,
        ),
      ),
    );
  }
}

// ── Mini Equalizer Animation ───────────────────────────────────

class _MiniEqualizer extends StatefulWidget {
  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final phase = (i * 0.25 + _controller.value) % 1.0;
            final h = 2.0 + phase * 6.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
              width: 2,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Queue Bottom Sheet ─────────────────────────────────────────

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioService.instance,
      builder: (context, _) {
        final audio = AudioService.instance;
        final queue = audio.queue;
        final currentIdx = audio.queueIndex;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.queue_music, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Now Playing',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),

                      // Shuffle
                      GestureDetector(
                        onTap: audio.toggleShuffle,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: audio.shuffled
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shuffle,
                            size: 18,
                            color: audio.shuffled
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Repeat
                      GestureDetector(
                        onTap: audio.cycleRepeat,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: audio.repeatMode != RepeatMode.off
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            audio.repeatMode == RepeatMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                            size: 18,
                            color: audio.repeatMode != RepeatMode.off
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Track count
                      Text(
                        '${currentIdx + 1}/${queue.length}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.outlineVariant),

                // Queue list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (_, i) {
                      final track = queue[i];
                      final isCurrent = i == currentIdx;

                      return GestureDetector(
                        onTap: () => audio.playTrack(track, queue: queue),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              // Index or equalizer
                              SizedBox(
                                width: 28,
                                child: isCurrent && audio.isPlaying
                                    ? _MiniEqualizer()
                                    : Text(
                                        '${i + 1}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 12,
                                          color: isCurrent
                                              ? AppColors.primary
                                              : AppColors.onSurfaceVariant,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),

                              // Track info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isCurrent
                                            ? AppColors.primary
                                            : AppColors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track.artist,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Format badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  track.ext.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
