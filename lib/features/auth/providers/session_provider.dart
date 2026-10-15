import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demo grants navigation access only; it is never an authenticated account.
enum SessionMode { unauthenticated, demo, authenticated }

final sessionProvider = NotifierProvider<SessionController, SessionMode>(
  SessionController.new,
);

class SessionController extends Notifier<SessionMode> {
  @override
  SessionMode build() => SessionMode.unauthenticated;

  void enterDemo() {
    if (state == SessionMode.unauthenticated) state = SessionMode.demo;
  }

  void endDemo() {
    if (state == SessionMode.demo) state = SessionMode.unauthenticated;
  }
}
