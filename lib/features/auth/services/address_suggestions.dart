import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressSuggestion {
  const AddressSuggestion({
    required this.line1,
    required this.city,
    required this.stateCode,
    required this.zip,
  });
  final String line1, city, stateCode, zip;
  String get subtitle => '$city, $stateCode $zip';
}

abstract class AddressSuggestionSource {
  Future<List<AddressSuggestion>> search(String query);
}

/// Local Figma demo data, not a real address lookup or verification service.
class MockAddressSuggestions implements AddressSuggestionSource {
  @override
  Future<List<AddressSuggestion>> search(String query) async {
    const example = AddressSuggestion(
      line1: '254 W 107th St',
      city: 'New York',
      stateCode: 'NY',
      zip: '10025',
    );
    final term = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return term.isNotEmpty &&
            '${example.line1} ${example.subtitle}'.toLowerCase().contains(term)
        ? [example]
        : [];
  }
}

final addressSuggestionSourceProvider = Provider<AddressSuggestionSource>(
  (ref) => MockAddressSuggestions(),
);
