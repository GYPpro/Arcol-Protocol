import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'column_layout.dart';
import 'resizable_divider.dart';

class DashboardLayout extends StatefulWidget {
  final List<Widget> cards;
  final int defaultColumns;
  final String storageKey;

  const DashboardLayout({
    super.key,
    required this.cards,
    this.defaultColumns = 2,
    this.storageKey = 'dashboard_layout',
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  late int _columnCount;
  late List<double> _columnWidths;
  late List<int> _cardOrders;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _columnCount = widget.defaultColumns;
    _columnWidths = List.generate(_columnCount, (_) => 1.0);
    _cardOrders = List.generate(widget.cards.length, (i) => i);
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(widget.storageKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        setState(() {
          _columnCount = data['columns'] ?? widget.defaultColumns;
          _columnWidths = (data['columnWidths'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
              List.generate(_columnCount, (_) => 1.0);
          _cardOrders = (data['cardOrders'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
              List.generate(widget.cards.length, (i) => i);
        });
      }
    } catch (e) {
      debugPrint('Error loading layout: $e');
    }
    setState(() => _isLoaded = true);
  }

  Future<void> _saveLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'columns': _columnCount,
        'columnWidths': _columnWidths,
        'cardOrders': _cardOrders,
      };
      await prefs.setString(widget.storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving layout: $e');
    }
  }

  void _updateColumnWidth(int index, double width) {
    setState(() {
      final total = _columnWidths.reduce((a, b) => a + b);
      _columnWidths[index] = width;
      final newTotal = _columnWidths.reduce((a, b) => a + b);
      // Normalize
      _columnWidths = _columnWidths.map((w) => w / newTotal * total).toList();
    });
    _saveLayout();
  }

  void _onCardDropped(String draggedId, String targetId) {
    // Parse IDs
    final draggedMatch = RegExp(r'col(\d+)_card_(\d+)').firstMatch(draggedId);
    final targetMatch = RegExp(r'col(\d+)_card_(\d+)').firstMatch(targetId);
    
    if (draggedMatch == null || targetMatch == null) return;

    final draggedCol = int.parse(draggedMatch.group(1)!);
    final draggedIdx = int.parse(draggedMatch.group(2)!);
    final targetCol = int.parse(targetMatch.group(1)!);
    final targetIdx = int.parse(targetMatch.group(2)!);

    setState(() {
      // Calculate the actual card index
      final List<List<int>> columnCards = List.generate(_columnCount, (_) => []);
      
      // Build current order
      for (int i = 0; i < _cardOrders.length; i++) {
        final cardIdx = _cardOrders[i];
        columnCards[i % _columnCount].add(i);
      }

      // Move card
      if (draggedCol == targetCol) {
        // Same column - reorder
        final cards = columnCards[draggedCol];
        final oldPos = cards.indexOf(draggedIdx);
        final newPos = cards.indexOf(targetIdx);
        if (oldPos != -1 && newPos != -1) {
          cards.removeAt(oldPos);
          cards.insert(newPos > oldPos ? newPos - 1 : newPos, draggedIdx);
        }
      } else {
        // Different column - move
        columnCards[draggedCol].remove(draggedIdx);
        columnCards[targetCol].insert(targetIdx, draggedIdx);
      }

      // Rebuild card orders
      _cardOrders = [];
      for (var col in columnCards) {
        _cardOrders.addAll(col);
      }
    });
    _saveLayout();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // Distribute cards to columns
    final columns = List.generate(_columnCount, (colIndex) {
      final columnCards = <Widget>[];
      for (int i = 0; i < widget.cards.length; i++) {
        if (i % _columnCount == colIndex) {
          columnCards.add(SizedBox(
            height: 200,
            child: widget.cards[_cardOrders[i]],
          ));
        }
      }
      
      return DashboardColumn(
        columnIndex: colIndex,
        cards: columnCards,
        initialWidth: MediaQuery.of(context).size.width * _columnWidths[colIndex] / _columnCount - 20,
        minWidth: 200,
        maxWidth: 800,
        onWidthChanged: (w) => _updateColumnWidth(colIndex, w),
        onCardDropped: _onCardDropped,
      );
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        
        return Row(
          children: [
            for (int i = 0; i < _columnCount; i++) ...[
              if (i > 0)
                ResizableDivider(
                  onDrag: (delta) {
                    _updateColumnWidth(i, _columnWidths[i] + delta / totalWidth);
                  },
                ),
              Expanded(
                flex: (_columnWidths[i] * 100).toInt(),
                child: columns[i],
              ),
            ],
          ],
        );
      },
    );
  }
}
