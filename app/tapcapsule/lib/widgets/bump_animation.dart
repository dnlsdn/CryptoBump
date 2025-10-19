import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ui/theme.dart';

enum BumpAnimationState {
  idle,
  searching,
  approaching,
  connected,
  transferring,
  complete,
}

class BumpAnimation extends StatefulWidget {
  final BumpAnimationState state;
  final bool isSender;

  const BumpAnimation({
    super.key,
    required this.state,
    required this.isSender,
  });

  @override
  State<BumpAnimation> createState() => _BumpAnimationState();
}

class _BumpAnimationState extends State<BumpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late AnimationController _approachController;
  late AnimationController _glowController;
  late AnimationController _transferController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _approachController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _transferController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(BumpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _handleStateChange();
    }
  }

  void _handleStateChange() {
    switch (widget.state) {
      case BumpAnimationState.searching:
        _searchController.repeat();
        break;
      case BumpAnimationState.approaching:
        _searchController.stop();
        _approachController.forward(from: 0);
        break;
      case BumpAnimationState.connected:
        _glowController.repeat(reverse: true);
        _particleController.repeat();
        break;
      case BumpAnimationState.transferring:
        _transferController.forward(from: 0);
        break;
      case BumpAnimationState.complete:
        _glowController.stop();
        _particleController.stop();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _approachController.dispose();
    _glowController.dispose();
    _transferController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          // Background glow
          if (widget.state == BumpAnimationState.connected ||
              widget.state == BumpAnimationState.transferring)
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: 300 + (_glowController.value * 50),
                    height: 300 + (_glowController.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.3 * (1 - _glowController.value)),
                          AppTheme.accent.withOpacity(0.2 * (1 - _glowController.value)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Particles
          if (widget.state == BumpAnimationState.connected ||
              widget.state == BumpAnimationState.transferring)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    progress: _particleController.value,
                    isSender: widget.isSender,
                  ),
                  size: const Size(double.infinity, 400),
                );
              },
            ),

          // Devices
          AnimatedBuilder(
            animation: Listenable.merge([_searchController, _approachController]),
            builder: (context, child) {
              final approachProgress = _approachController.value;
              final searchProgress = _searchController.value;

              return Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Left device (this device)
                    Transform.translate(
                      offset: Offset(
                        widget.state == BumpAnimationState.searching
                            ? -100 + (math.sin(searchProgress * math.pi * 2) * 10)
                            : widget.state == BumpAnimationState.approaching
                                ? -100 + (approachProgress * 40)
                                : -60,
                        0,
                      ),
                      child: _buildDevice(
                        color: widget.isSender ? AppTheme.primary : AppTheme.accent,
                        label: 'You',
                        isActive: true,
                      ),
                    ),

                    // Right device (other device)
                    Transform.translate(
                      offset: Offset(
                        widget.state == BumpAnimationState.searching
                            ? 100 + (math.sin(searchProgress * math.pi * 2) * -10)
                            : widget.state == BumpAnimationState.approaching
                                ? 100 - (approachProgress * 40)
                                : 60,
                        0,
                      ),
                      child: _buildDevice(
                        color: widget.isSender ? AppTheme.accent : AppTheme.primary,
                        label: 'Device',
                        isActive: widget.state != BumpAnimationState.idle &&
                            widget.state != BumpAnimationState.searching,
                      ),
                    ),

                    // Transfer data animation
                    if (widget.state == BumpAnimationState.transferring)
                      AnimatedBuilder(
                        animation: _transferController,
                        builder: (context, child) {
                          final start = widget.isSender ? -60.0 : 60.0;
                          final end = widget.isSender ? 60.0 : -60.0;
                          final position = start + ((end - start) * _transferController.value);

                          return Transform.translate(
                            offset: Offset(position, 0),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppTheme.success, AppTheme.accent],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withOpacity(0.6),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),

          // Status text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _buildStatusText(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice({
    required Color color,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [color, color.withOpacity(0.7)]
                  : [
                      AppTheme.darkCard.withOpacity(0.6),
                      AppTheme.darkCard.withOpacity(0.4),
                    ],
            ),
            border: Border.all(
              color: isActive ? color : Colors.white.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              Icons.phone_iphone,
              color: isActive ? Colors.white : AppTheme.lightText.withOpacity(0.3),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.lightText : AppTheme.lightText.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    String text;
    Color color;

    switch (widget.state) {
      case BumpAnimationState.searching:
        text = 'Searching for nearby device...';
        color = AppTheme.lightText.withOpacity(0.7);
        break;
      case BumpAnimationState.approaching:
        text = 'Device found!';
        color = AppTheme.accent;
        break;
      case BumpAnimationState.connected:
        text = 'Connected';
        color = AppTheme.success;
        break;
      case BumpAnimationState.transferring:
        text = widget.isSender ? 'Sending voucher...' : 'Receiving voucher...';
        color = AppTheme.primary;
        break;
      case BumpAnimationState.complete:
        text = widget.isSender ? 'Sent successfully!' : 'Received successfully!';
        color = AppTheme.success;
        break;
      default:
        text = 'Tap to start';
        color = AppTheme.lightText.withOpacity(0.5);
    }

    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final bool isSender;

  ParticlePainter({required this.progress, required this.isSender});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final distance = 60 + (progress * 40);
      final x = centerX + math.cos(angle) * distance;
      final y = centerY + math.sin(angle) * distance;

      paint.color = (i % 2 == 0 ? AppTheme.primary : AppTheme.accent)
          .withOpacity(0.6 * (1 - progress));

      canvas.drawCircle(
        Offset(x, y),
        4 * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
