import 'package:flutter/foundation.dart';

import '../models/evidence_model.dart';

class EvidenceController extends ChangeNotifier {
  final List<EvidenceModel> _items = [];
  String? _selectedId;
  List<EvidenceModel> get items => List.unmodifiable(_items);
  EvidenceModel? get selected =>
      _items.where((item) => item.id == _selectedId).firstOrNull;
  void add(EvidenceModel item) {
    if (_items.any((value) => value.id == item.id)) return;
    _items.add(item);
    _selectedId = item.id;
    notifyListeners();
  }

  void select(String id) {
    if (_selectedId == id || !_items.any((item) => item.id == id)) return;
    _selectedId = id;
    notifyListeners();
  }

  void remove(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _items.removeAt(index);
    if (_selectedId == id) {
      _selectedId = _items.isEmpty
          ? null
          : _items[index.clamp(0, _items.length - 1)].id;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _items.clear();
    _selectedId = null;
    super.dispose();
  }
}
