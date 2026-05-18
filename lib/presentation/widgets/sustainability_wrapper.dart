import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

// =============================================
// ==== CLASE SustainabilityWrapper =====
// Descripción: Widget envoltura enfocado en la sostenibilidad energética que detecta la inactividad del usuario por un periodo determinado (por defecto, 5 minutos) y activa un modo de suspensión visual con desenfoque de cristal y bajo consumo.
// =============================================
class SustainabilityWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeout;

  const SustainabilityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5),
  });

  @override
  State<SustainabilityWrapper> createState() => _SustainabilityWrapperState();
}

class _SustainabilityWrapperState extends State<SustainabilityWrapper> {
  Timer? _timer;
  bool _isSuspended = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      setState(() {
        _isSuspended = true;
      });
    });
  }

  void _handleInteraction([dynamic _]) {
    if (_isSuspended) {
      setState(() {
        _isSuspended = false;
      });
    }
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleInteraction,
      onPointerMove: _handleInteraction,
      onPointerHover: _handleInteraction,
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) => _handleInteraction(),
        child: Stack(
          children: [
            widget.child,
            if (_isSuspended)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _handleInteraction,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10.0 * value,
                          sigmaY: 10.0 * value,
                        ),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.7 * value),
                          child: child,
                        ),
                      );
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.eco_rounded,
                            color: Colors.greenAccent.withValues(alpha: 0.8),
                            size: 80,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'MODO SOSTENIBILIDAD',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Haz clic o presiona cualquier tecla para despertar',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 40),
                          const _PulseCircle(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  const _PulseCircle();

  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
      builder: (context, child) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent.withValues(alpha: 1.0 - _controller.value),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.5 * (1.0 - _controller.value)),
                blurRadius: 20 * _controller.value,
                spreadRadius: 10 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
