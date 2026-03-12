import 'package:flutter/material.dart';

class DraggableCard extends StatefulWidget {
  final String cardId;
  final Widget child;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final void Function(String targetId)? onDropped;

  const DraggableCard({
    super.key,
    required this.cardId,
    required this.child,
    this.onDragStarted,
    this.onDragEnd,
    this.onDropped,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<String>(
      data: widget.cardId,
      delay: const Duration(milliseconds: 200),
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStarted?.call();
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
        widget.onDragEnd?.call();
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isDragging = false);
        widget.onDragEnd?.call();
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Opacity(
            opacity: 0.8,
            child: widget.child,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.child,
      ),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          if (details.data != widget.cardId) {
            setState(() => _isHovering = true);
            return true;
          }
          return false;
        },
        onLeave: (_) {
          setState(() => _isHovering = false);
        },
        onAcceptWithDetails: (details) {
          setState(() => _isHovering = false);
          widget.onDropped?.call(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: _isHovering
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : _isDragging
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        )
                      : null,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}
