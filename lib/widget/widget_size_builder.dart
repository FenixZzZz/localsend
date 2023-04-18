import 'package:flutter/material.dart';

class NullableSize {
  final double? width;
  final double? height;

  const NullableSize({
    this.width,
    this.height,
  });

  @override
  String toString() => 'NullableSize(width: $width, height: $height)';
}

/// A widget that is sized based on the size of [referenceWidgets].
class WidgetSizeBuilder extends StatefulWidget {
  final List<WidgetBuilder> referenceWidgets;
  final NullableSize Function(List<Size> sizes) onSizes;
  final NullableSize defaultSize;
  final Widget child;

  /// Adds a delay to the size calculation.
  /// Usually for testing purposes.
  final Duration delay;

  const WidgetSizeBuilder({
    required this.referenceWidgets,
    required this.onSizes,
    required this.defaultSize,
    this.delay = Duration.zero,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  State<WidgetSizeBuilder> createState() => _WidgetSizeBuilderState();
}

class _WidgetSizeBuilderState extends State<WidgetSizeBuilder> {
  late List<GlobalKey> _globalKeys;
  late NullableSize _size;
  bool _gotSize = false;

  @override
  void initState() {
    super.initState();
    _globalKeys = widget.referenceWidgets.map((_) => GlobalKey()).toList();
    _size = widget.defaultSize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureReferenceWidgets();
    });
  }

  void _measureReferenceWidgets() async {
    await Future.delayed(widget.delay);
    if (!mounted) {
      return;
    }

    setState(() {
      final sizes = _globalKeys
        .map((key) => (key.currentContext!.findRenderObject()! as RenderBox).size)
        .toList();

      _size = widget.onSizes(sizes);
      _gotSize = true;
    });
  }

  @override
  void didUpdateWidget(covariant WidgetSizeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceWidgets != widget.referenceWidgets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureReferenceWidgets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int i = 0; i < widget.referenceWidgets.length; i++)
          Visibility(
            key: _globalKeys[i],
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: false,
            child: widget.referenceWidgets[i](context),
          ),
        SizedBox(
          width: _size.width,
          height: _size.height,
          child: _gotSize ? widget.child : null,
        ),
      ],
    );
  }
}
