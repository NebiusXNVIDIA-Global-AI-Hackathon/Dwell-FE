import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sign_up_draft.dart';

/// Both route pages watch this provider. Leaving the entire flow clears it.
final signUpProvider =
    NotifierProvider.autoDispose<SignUpController, SignUpDraft>(
      SignUpController.new,
    );

class SignUpController extends Notifier<SignUpDraft> {
  @override
  SignUpDraft build() => const SignUpDraft();

  void update(SignUpDraft draft) => state = draft;
}
