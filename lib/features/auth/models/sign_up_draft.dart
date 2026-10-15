import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../data/us_states.dart';

/// Sensitive, in-memory form data only. Do not log, persist or serialize it.
@immutable
class SignUpDraft {
  const SignUpDraft({
    this.nickname = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailLocalPart = '',
    this.emailDomain = '',
    this.addressLine1 = '',
    this.apartment = '',
    this.city = '',
    this.stateCode = '',
    this.zipCode = '',
    this.passwordTouched = false,
    this.confirmTouched = false,
  });
  final String nickname, password, confirmPassword, emailLocalPart, emailDomain;
  final String addressLine1, apartment, city, stateCode, zipCode;
  final bool passwordTouched, confirmTouched;

  // Temporary Figma policy; align with the backend before enabling real signup.
  bool get validPassword =>
      password.characters.length >= 6 && password.characters.length <= 8;
  bool get validEmail =>
      const ['naver.com', 'daum.net', 'google.com'].contains(emailDomain) &&
      RegExp(
        r'^[a-zA-Z0-9!#$%&\x27*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&\x27*+/=?^_`{|}~-]+)*$',
      ).hasMatch(emailLocalPart.trim());
  String get email => '${emailLocalPart.trim()}@$emailDomain';
  String? get passwordError => passwordTouched && !validPassword
      ? 'Password must be 6-8 characters long.'
      : null;
  String? get confirmError => confirmTouched && password != confirmPassword
      ? 'Passwords do not match.'
      : null;
  bool get canContinue =>
      nickname.trim().isNotEmpty &&
      validPassword &&
      password == confirmPassword &&
      validEmail;
  bool get validAddress =>
      addressLine1.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      usStates.containsKey(stateCode) &&
      RegExp(r'^\d{5}$').hasMatch(zipCode.trim());
  bool get canSubmit => canContinue && validAddress;
  SignUpDraft get normalized => copyWith(
    nickname: nickname.trim(),
    emailLocalPart: emailLocalPart.trim(),
    addressLine1: addressLine1.trim(),
    apartment: apartment.trim(),
    city: city.trim(),
    zipCode: zipCode.trim(),
  );

  SignUpDraft copyWith({
    String? nickname,
    String? password,
    String? confirmPassword,
    String? emailLocalPart,
    String? emailDomain,
    String? addressLine1,
    String? apartment,
    String? city,
    String? stateCode,
    String? zipCode,
    bool? passwordTouched,
    bool? confirmTouched,
  }) => SignUpDraft(
    nickname: nickname ?? this.nickname,
    password: password ?? this.password,
    confirmPassword: confirmPassword ?? this.confirmPassword,
    emailLocalPart: emailLocalPart ?? this.emailLocalPart,
    emailDomain: emailDomain ?? this.emailDomain,
    addressLine1: addressLine1 ?? this.addressLine1,
    apartment: apartment ?? this.apartment,
    city: city ?? this.city,
    stateCode: stateCode ?? this.stateCode,
    zipCode: zipCode ?? this.zipCode,
    passwordTouched: passwordTouched ?? this.passwordTouched,
    confirmTouched: confirmTouched ?? this.confirmTouched,
  );
}
