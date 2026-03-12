import 'package:flutter/material.dart';

class ResizableDivider extends StatefulWidget {
  final double width;
  final ValueChanged<double> onDrag;
  final double minWidth;
  final double maxWidth;

  const ResizableDivider({
    super.key,
    this.width = 8,
    required this.onDrag,
    this.minWidth = 100,
    this.maxWidth = 800,
  });

  @override
  State<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends State<ResizableDivider> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        onHorizontalDragUpdate: (details) {
          widget.onDrag(details.delta.dx);
        },
        child: Container(
          width: widget.width,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isHovering || _isDragging ? 6 : 4,
              decoration: BoxDecoration(
                color: _isHovering || _isDragging
                    ? theme.colorScheme.primary.withOpacity(0.5)
                    : theme.colorScheme.outlineVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
