import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Override with the current user's display name when profiles are connected.
/// No account data or authentication state is created by this provider.
final profileNicknameProvider = Provider<String?>((ref) => null);
