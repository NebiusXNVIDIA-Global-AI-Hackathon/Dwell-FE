import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

import '../models/case_filters.dart';

class CaseFilterTags extends StatefulWidget {
  final CaseFilters filters;
  final void Function(CaseFilterGroup group, String value) onRemove;
  final VoidCallback onReset;

  const CaseFilterTags({
    super.key,
    required this.filters,
    required this.onRemove,
    required this.onReset,
  });

  @override
  State<CaseFilterTags> createState() => _CaseFilterTagsState();
}

class _CaseFilterTagsState extends State<CaseFilterTags> {
  final _scrollController = ScrollController();
  bool _fadeLeft = false;
  bool _fadeRight = false;
  bool _edgeUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateEdges);
    _scheduleEdgeUpdate();
  }

  @override
  void didUpdateWidget(covariant CaseFilterTags oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.filters.sameAs(oldWidget.filters)) {
      _scheduleEdgeUpdate();
    }
  }

  void _scheduleEdgeUpdate() {
    if (_edgeUpdateScheduled) return;
    _edgeUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _edgeUpdateScheduled = false;
      if (mounted) _updateEdges();
    });
  }

  void _updateEdges() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    final left = position.pixels > position.minScrollExtent + 0.5;
    final right = position.pixels < position.maxScrollExtent - 0.5;
    if (left == _fadeLeft && right == _fadeRight) return;

    setState(() {
      _fadeLeft = left;
      _fadeRight = right;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateEdges);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final tags = widget.filters.tags;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _scheduleEdgeUpdate();
                    return false;
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.invertedStylus,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tag in tags)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InputChip(
                                key: ValueKey(tag.group.name + ':' + tag.value),
                                label: Text(tag.value),
                                onDeleted: () =>
                                    widget.onRemove(tag.group, tag.value),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                deleteIconColor: colors.onSurfaceVariant,
                                backgroundColor:
                                    colors.brightness == Brightness.light
                                    ? const Color(0xFFE4E4E4)
                                    : colors.surfaceContainerHighest,
                                labelStyle: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                                side: BorderSide.none,
                                shape: const StadiumBorder(),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_fadeLeft)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              background,
                              background.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_fadeRight)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 24,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              background.withValues(alpha: 0),
                              background,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: widget.onReset,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF007AFF),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
