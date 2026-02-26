import 'dart:async';

import 'package:flutter/material.dart';

class EaseFlashPlaceholder extends StatefulWidget {
  const EaseFlashPlaceholder({
    super.key,
    this.duration,
    this.color,
    this.width,
    this.height,
  });

  final Duration? duration;
  final Color? color;
  final double? width;
  final double? height;

  @override
  State<EaseFlashPlaceholder> createState() => _EaseFlashPlaceholderState();
}

class _EaseFlashPlaceholderState extends State<EaseFlashPlaceholder> {
  static const Duration _defaultDuration = Duration(milliseconds: 600);
  bool _isVisible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.duration ?? _defaultDuration, (Timer timer) {
      setState(() {
        _isVisible = !_isVisible;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: widget.duration ?? _defaultDuration,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.color ?? Theme.of(context).colorScheme.surfaceContainer,
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
