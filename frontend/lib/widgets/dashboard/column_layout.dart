import 'package:flutter/material.dart';
import 'draggable_card.dart';

class DashboardColumn extends StatefulWidget {
  final int columnIndex;
  final List<Widget> cards;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  final ValueChanged<double>? onWidthChanged;
  final void Function(String draggedId, String targetId)? onCardDropped;

  const DashboardColumn({
    super.key,
    required this.columnIndex,
    required this.cards,
    this.initialWidth = 400,
    this.minWidth = 200,
    this.maxWidth = 800,
    this.onWidthChanged,
    this.onCardDropped,
  });

  @override
  State<DashboardColumn> createState() => _DashboardColumnState();
}

class _DashboardColumnState extends State<DashboardColumn> {
  late double _width;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  void didUpdateWidget(DashboardColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWidth != widget.initialWidth) {
      _width = widget.initialWidth;
    }
  }

  void _handleDrag(double delta) {
    setState(() {
      _width = (_width + delta).clamp(widget.minWidth, widget.maxWidth);
    });
    widget.onWidthChanged?.call(_width);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: widget.cards.length,
              onReorder: (oldIndex, newIndex) {
                // Reorder logic handled by parent
              },
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final card = widget.cards[index];
                final cardKey = 'col${widget.columnIndex}_card_$index';
                return ReorderableDragStartListener(
                  key: ValueKey(cardKey),
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: DraggableCard(
                      cardId: cardKey,
                      onDropped: (draggedId) {
                        widget.onCardDropped?.call(draggedId, cardKey);
                      },
                      child: card,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
