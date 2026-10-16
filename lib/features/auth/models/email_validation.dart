/// Validates the unquoted local part used by the existing email forms.
bool isValidEmailLocalPart(String value) => _localPart.hasMatch(value.trim());

final _localPart = RegExp(
  r"^[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*$",
);
