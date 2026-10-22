import 'package:flutter_riverpod/flutter_riverpod.dart';

/// IDs removed from the mock data during this session.
final deletedCaseIdsProvider =
    NotifierProvider<DeletedCaseIdsNotifier, Set<String>>(
      DeletedCaseIdsNotifier.new,
    );

class DeletedCaseIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String caseId) => state = {...state, caseId};
}
