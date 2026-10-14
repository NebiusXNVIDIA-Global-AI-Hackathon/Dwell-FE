import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

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
