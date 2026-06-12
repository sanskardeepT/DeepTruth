import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/trust_verification_models.dart';

class TrustGraphWidget extends StatefulWidget {
  final TrustGraph graph;

  const TrustGraphWidget({
    super.key,
    required this.graph,
  });

  @override
  State<TrustGraphWidget> createState() => _TrustGraphWidgetState();
}

class _TrustGraphWidgetState extends State<TrustGraphWidget> {
  TrustGraphNode? _selectedNode;
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _calculatePositions();
  }

  void _calculatePositions() {
    // Lay out nodes in vertical columns from left to right based on entity types (Dissemination Lineage)
    final nodes = widget.graph.nodes;
    final Map<String, List<TrustGraphNode>> columns = {
      'Source': [], // Person, Organization
      'Media':  [], // Media, DeepfakeFamily
      'Network':[], // Domain, Campaign, BotNetwork
    };

    for (final node in nodes) {
      if (node.type == 'Person' || node.type == 'Organization') {
        columns['Source']!.add(node);
      } else if (node.type == 'Media' || node.type == 'DeepfakeFamily') {
        columns['Media']!.add(node);
      } else {
        columns['Network']!.add(node);
      }
    }

    final double width = 340.0;
    final double height = 240.0;

    final colKeys = ['Source', 'Media', 'Network'];
    for (int colIdx = 0; colIdx < colKeys.length; colIdx++) {
      final key = colKeys[colIdx];
      final colNodes = columns[key]!;
      final double colX = 40.0 + colIdx * (width / 2.5);

      for (int i = 0; i < colNodes.length; i++) {
        final node = colNodes[i];
        final double spacing = height / (colNodes.length + 1);
        final double nodeY = spacing * (i + 1);
        _positions[node.id] = Offset(colX, nodeY);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.graph.nodes.isEmpty) {
      return const Center(
        child: Text(
          'No Graph Lineage Data Available',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.8,
              maxScale: 2.0,
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTap(details.localPosition);
                },
                child: CustomPaint(
                  size: const Size(400, 250),
                  painter: _GraphPainter(
                    graph:     widget.graph,
                    positions: _positions,
                    selected:  _selectedNode,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_selectedNode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                _buildTypeIcon(_selectedNode!.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedNode!.label,
                        style: const TextStyle(
                          color:      AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Type: ${_selectedNode!.type} | ${_selectedNode!.properties.entries.map((e) => "${e.key}: ${e.value}").join(", ")}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
                  onPressed: () => setState(() => _selectedNode = null),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _handleTap(Offset localPos) {
    TrustGraphNode? tapped;
    double minDistance = 20.0;

    _positions.forEach((id, pos) {
      final dist = (localPos - pos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        tapped = widget.graph.nodes.firstWhere((n) => n.id == id);
      }
    });

    if (tapped != _selectedNode) {
      setState(() => _selectedNode = tapped);
    }
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'Person':
        icon = Icons.person_rounded;
        color = Colors.blue;
      case 'Organization':
        icon = Icons.business_rounded;
        color = Colors.purple;
      case 'Media':
        icon = Icons.photo_library_rounded;
        color = AppColors.accent;
      case 'Campaign':
        icon = Icons.crisis_alert_rounded;
        color = AppColors.danger;
      case 'BotNetwork':
        icon = Icons.smart_toy_rounded;
        color = Colors.orange;
      case 'DeepfakeFamily':
        icon = Icons.psychology_rounded;
        color = Colors.pink;
      default:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        shape:        BoxShape.circle,
        border:       Border.all(color: color, width: 1),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final TrustGraph graph;
  final Map<String, Offset> positions;
  final TrustGraphNode? selected;

  const _GraphPainter({
    required this.graph,
    required this.positions,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw connection arrows (Edges)
    final linePaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.fill;

    for (final edge in graph.edges) {
      final start = positions[edge.from];
      final end = positions[edge.to];
      if (start != null && end != null) {
        // Draw edge line
        canvas.drawLine(start, end, linePaint);

        // Draw arrow indicator at middle
        final double midX = (start.dx + end.dx) / 2;
        final double midY = (start.dy + end.dy) / 2;
        final angle = atan2(end.dy - start.dy, end.dx - start.dx);

        final arrowSize = 6.0;
        final path = Path()
          ..moveTo(midX, midY)
          ..lineTo(midX - arrowSize * cos(angle - pi / 6), midY - arrowSize * sin(angle - pi / 6))
          ..lineTo(midX - arrowSize * cos(angle + pi / 6), midY - arrowSize * sin(angle + pi / 6))
          ..close();
        canvas.drawPath(path, arrowPaint);
      }
    }

    // 2. Draw nodes (Vertices)
    for (final node in graph.nodes) {
      final pos = positions[node.id];
      if (pos == null) continue;

      final isSel = selected?.id == node.id;
      final color = _getNodeColor(node.type);

      // Outer highlight ring for selected
      if (isSel) {
        final ringPaint = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 18, ringPaint);
      }

      // Main node circle
      final nodePaint = Paint()
        ..color = isSel ? color : AppColors.bgCard
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 12, nodePaint);

      // Node border
      final borderPaint = Paint()
        ..color = isSel ? Colors.white : color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 12, borderPaint);

      // Typographical letter representation inside circle
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.type.substring(0, 1),
          style: TextStyle(
            color:      isSel ? Colors.black : AppColors.textPrimary,
            fontSize:   9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );

      // Label under node
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.label.length > 15 ? '${node.label.substring(0, 12)}…' : node.label,
          style: TextStyle(
            color:      isSel ? Colors.white : AppColors.textSecondary,
            fontSize:   7.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(pos.dx - labelPainter.width / 2, pos.dy + 16),
      );
    }
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'Person':          return Colors.blue;
      case 'Organization':    return Colors.purple;
      case 'Media':           return AppColors.accent;
      case 'Campaign':        return AppColors.danger;
      case 'BotNetwork':      return Colors.orange;
      case 'DeepfakeFamily':  return Colors.pink;
      default:                return AppColors.textMuted;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
