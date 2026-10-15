import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.ready, this.onCompleted});

  /// Optional startup work must finish before leaving, after the minimum delay.
  final Future<void>? ready;
  final VoidCallback? onCompleted;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _completed = false;
  bool _elapsed = false;
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.onCompleted != null) {
      _timer = Timer(const Duration(seconds: 2), () {
        _elapsed = true;
        _complete();
      });
    }
    _waitForReady();
  }

  @override
  void didUpdateWidget(covariant SplashPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ready != widget.ready) _waitForReady();
  }

  Future<void> _waitForReady() async {
    final ready = widget.ready;
    _ready = ready == null;
    if (ready == null) {
      _complete();
      return;
    }
    if (_completed) return;
    try {
      await ready;
      if (mounted && ready == widget.ready && !_completed) {
        _ready = true;
        _complete();
      }
    } catch (_) {
      // An unsuccessful startup must not advance to Login.
    }
  }

  void _complete() {
    if (!mounted || _completed || !_elapsed || !_ready) return;
    _completed = true;
    _timer?.cancel();
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8F6F1),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F1),
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8F6F1), Color(0xFFF8F8F8)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Semantics(
                      image: true,
                      label: 'Dwell. Live well where you dwell',
                      child: ExcludeSemantics(
                        child: MediaQuery.withNoTextScaling(
                          child: SizedBox(
                            key: const ValueKey('splash-logo'),
                            width: 386,
                            height: 207,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/dwell_logo.svg',
                                  width: 210,
                                  height: 207,
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 32),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.bottomLeft,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dwell',
                                            style: TextStyle(
                                              color: Color(0xFF243B53),
                                              fontSize: 42,
                                              fontWeight: FontWeight.w800,
                                              height: 1,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Live well\nwhere you dwell',
                                            style: TextStyle(
                                              color: Color(0xFFED9B36),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
