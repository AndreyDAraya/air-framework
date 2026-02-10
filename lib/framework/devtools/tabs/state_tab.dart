import 'package:flutter/material.dart';
import '../../state/air.dart';
import '../widgets/shared_widgets.dart';

class StateTab extends StatefulWidget {
  const StateTab({super.key});

  @override
  State<StateTab> createState() => _StateTabState();
}

class _StateTabState extends State<StateTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedKeys = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statesMap = Air().debugStates;
    final keys = statesMap.keys
        .where((k) => k.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        buildSearchBar(
          controller: _searchController,
          hint: 'Search states...',
          onChanged: (v) => setState(() => _searchQuery = v),
          onClear: () => setState(() {
            _searchController.clear();
            _searchQuery = '';
          }),
        ),
        Expanded(
          child: keys.isEmpty
              ? emptyState(Icons.cloud_off, 'No matching AirStates')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    final controller = statesMap[key]!;

                    return buildDebugCard(
                      icon: Icons.psychology_outlined,
                      iconColor: Colors.blueAccent,
                      title: key,
                      subtitle:
                          controller.value is List || controller.value is Map
                          ? '${controller.value.runtimeType} (${controller.value.length})'
                          : controller.value.toString(),
                      trailing: controller.value.runtimeType.toString(),
                      extraWidget: _buildValueInspector(
                        key,
                        controller.value,
                        isRoot: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildValueInspector(
    String key,
    dynamic value, {
    bool isRoot = false,
  }) {
    if (value is Iterable && value is! Map) {
      final isExpanded = _expandedKeys.contains(key);
      final list = value.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedKeys.remove(key);
              } else {
                _expandedKeys.add(key);
              }
            }),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white38,
                  size: 16,
                ),
                Text(
                  '${value.runtimeType} [${list.length}]',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(list.length, (i) {
                  return _buildValueInspector('$key[$i]', list[i]);
                }),
              ),
            ),
        ],
      );
    }

    if (value is Map) {
      final isExpanded = _expandedKeys.contains(key);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedKeys.remove(key);
              } else {
                _expandedKeys.add(key);
              }
            }),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white38,
                  size: 16,
                ),
                Text(
                  'Map {${value.length}}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: value.entries.map<Widget>((e) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: _buildValueInspector('$key.${e.key}', e.value),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }

    final extractedData = _tryExtractData(value);
    if (extractedData != null) {
      return _buildValueInspector('$key*', extractedData);
    }

    if (!isRoot) {
      return Text(
        value.toString(),
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      );
    }

    return const SizedBox.shrink();
  }

  dynamic _tryExtractData(dynamic value) {
    if (value == null ||
        value is num ||
        value is String ||
        value is bool ||
        value is Iterable ||
        value is Map ||
        value is Enum) {
      return null;
    }

    try {
      return value.toJson();
    } catch (_) {
      try {
        return value.toMap();
      } catch (_) {
        return null;
      }
    }
  }
}
