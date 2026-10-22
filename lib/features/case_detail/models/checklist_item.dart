class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  final String id;
  final String text;
  final bool isDone;

  ChecklistItem copyWith({String? text, bool? isDone}) => ChecklistItem(
    id: id,
    text: text ?? this.text,
    isDone: isDone ?? this.isDone,
  );
}
