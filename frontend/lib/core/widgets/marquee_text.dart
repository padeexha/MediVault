import 'package:flutter/material.dart';

/// Scrolls horizontally when text is wider than its container.
/// Uses a ScrollController so it measures real post-layout overflow —
/// no LayoutBuilder / TextPainter needed.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({super.key, required this.text, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return; // text fits — nothing to do

    final t = _ctrl.value;
    double offset;
    // 0–20 %  : pause at start
    // 20–75 % : ease scroll to end
    // 75–90 % : pause at end
    // 90–100 %: jump back silently
    if (t < 0.20) {
      offset = 0;
    } else if (t < 0.75) {
      offset = Curves.easeInOut.transform((t - 0.20) / 0.55) * max;
    } else if (t < 0.90) {
      offset = max;
    } else {
      offset = 0;
    }

    _scroll.jumpTo(offset);
  }

  @override
  void didUpdateWidget(MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _ctrl
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_tick)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style ?? DefaultTextStyle.of(context).style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
