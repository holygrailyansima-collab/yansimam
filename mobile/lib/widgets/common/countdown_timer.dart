// ============================================
// File: lib/widgets/common/countdown_timer.dart
// Countdown Timer Widgets - Multiple variants for different use cases
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Countdown Timer Widget
/// Displays a countdown timer for voting sessions (72 hours)
class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTimerEnd;
  final bool showDays;
  final bool showLabels;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
    this.onTimerEnd,
    this.showDays = false,
    this.showLabels = true,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer?.cancel();
      widget.onTimerEnd?.call();
    } else {
      setState(() {
        _remainingTime = difference;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime == Duration.zero) {
      return _buildExpiredWidget();
    }

    if (widget.showDays) {
      return _buildTimerWithDays();
    } else {
      return _buildTimerWithoutDays();
    }
  }

  /// Build timer with days (DD:HH:MM:SS)
  Widget _buildTimerWithDays() {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeUnit(days.toString().padLeft(2, '0'), 'Gün'),
          _buildSeparator(),
          _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Saat'),
          _buildSeparator(),
          _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Dakika'),
          _buildSeparator(),
          _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Saniye'),
        ],
      ),
    );
  }

  /// Build timer without days (HH:MM:SS)
  Widget _buildTimerWithoutDays() {
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeUnit(hours.toString().padLeft(2, '0'), 'Saat'),
          _buildSeparator(),
          _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'Dakika'),
          _buildSeparator(),
          _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'Saniye'),
        ],
      ),
    );
  }

  /// Build single time unit (e.g., "12 Saat")
  Widget _buildTimeUnit(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: widget.textStyle ??
              const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ],
    );
  }

  /// Build separator (:)
  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  /// Build expired widget
  Widget _buildExpiredWidget() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off, color: AppColors.error),
          SizedBox(width: 8),
          Text(
            'Süre Doldu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// COMPACT COUNTDOWN TIMER
// ============================================

/// Compact Countdown Timer Widget
/// Smaller version for inline use (HH:MM:SS)
class CompactCountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final Color? color;
  final VoidCallback? onTimerEnd;

  const CompactCountdownTimer({
    super.key,
    required this.endTime,
    this.textStyle,
    this.color,
    this.onTimerEnd,
  });

  @override
  State<CompactCountdownTimer> createState() => _CompactCountdownTimerState();
}

class _CompactCountdownTimerState extends State<CompactCountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer?.cancel();
      widget.onTimerEnd?.call();
    } else {
      setState(() {
        _remainingTime = difference;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime == Duration.zero) {
      return Text(
        '00:00:00',
        style: widget.textStyle ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.color ?? AppColors.error,
            ),
      );
    }

    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$hours:$minutes:$seconds',
      style: widget.textStyle ??
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.color ?? AppColors.primary,
          ),
    );
  }
}

// ============================================
// CIRCULAR COUNTDOWN TIMER
// ============================================

/// Circular Countdown Timer Widget
/// Shows countdown in a circular progress indicator
class CircularCountdownTimer extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final VoidCallback? onTimerEnd;

  const CircularCountdownTimer({
    super.key,
    required this.startTime,
    required this.endTime,
    this.size = 120,
    this.strokeWidth = 8,
    this.progressColor,
    this.backgroundColor,
    this.textStyle,
    this.onTimerEnd,
  });

  @override
  State<CircularCountdownTimer> createState() => _CircularCountdownTimerState();
}

class _CircularCountdownTimerState extends State<CircularCountdownTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  double _progress = 1.0;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.endTime.difference(now);
    final totalDuration = widget.endTime.difference(widget.startTime);

    if (difference.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
        _progress = 0.0;
      });
      _timer?.cancel();
      widget.onTimerEnd?.call();
    } else {
      setState(() {
        _remainingTime = difference;
        _progress = difference.inSeconds / totalDuration.inSeconds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remainingTime.inHours.toString().padLeft(2, '0');
    final minutes = (_remainingTime.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: widget.strokeWidth,
              backgroundColor: widget.backgroundColor ?? AppColors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.backgroundColor ?? AppColors.grey.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: widget.strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.progressColor ?? _getProgressColor(),
              ),
            ),
          ),
          // Time text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$hours:$minutes',
                style: widget.textStyle ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
              ),
              Text(
                seconds,
                style: widget.textStyle?.copyWith(fontSize: 14) ??
                    const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Get progress color based on remaining time
  Color _getProgressColor() {
    if (_progress > 0.5) return AppColors.success;
    if (_progress > 0.25) return AppColors.warning;
    return AppColors.error;
  }
}
