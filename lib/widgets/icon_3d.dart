import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Glossy pressable 3D icon tile (ported from components/Icon3D.tsx).
/// Exposes [pressIn]/[pressOut] via [Icon3DController].
class Icon3DController {
  _Icon3DState? _state;

  void pressIn() => _state?._pressIn();
  void pressOut() => _state?._pressOut();
}

class Icon3D extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color bgColor;
  final double containerSize;
  final double borderRadius;
  final Icon3DController? controller;

  const Icon3D({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    required this.bgColor,
    this.containerSize = 52,
    this.borderRadius = 14,
    this.controller,
  });

  @override
  State<Icon3D> createState() => _Icon3DState();
}

class _Icon3DState extends State<Icon3D> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(Icon3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _anim.dispose();
    super.dispose();
  }

  void _pressIn() => _anim.forward();

  void _pressOut() => _anim.reverse();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.containerSize,
      height: widget.containerSize,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_anim.value);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 1 / 600)
            ..rotateY(t * 35 * math.pi / 180)
            ..rotateX(t * 20 * math.pi / 180)
            ..scaleByDouble(1 - t * 0.15, 1 - t * 0.15, 1, 1);
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            color: widget.bgColor,
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  child: Container(
                    width: widget.containerSize * 0.55,
                    height: widget.containerSize * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(0x26),
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: Radius.circular(widget.borderRadius),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    widget.icon,
                    size: widget.size,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
