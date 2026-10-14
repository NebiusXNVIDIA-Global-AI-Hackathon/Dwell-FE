import 'package:material_ui/material_ui.dart';

import '../../cases/models/case_model.dart';

/// Demo tab palette, not an API/business severity-color contract.
/// High follows the existing created-case badge. Medium uses the Figma tab;
/// unconfigured levels stay neutral until the production palette is confirmed.
const homeDemoSeverityColors = <CaseSeverity, Color>{
  CaseSeverity.high: Color(0xFFEDABA8),
  CaseSeverity.medium: Color(0xFFF0CE9C),
};

Color homeSeverityColor(
  CaseSeverity severity, {
  Map<CaseSeverity, Color> palette = homeDemoSeverityColors,
}) => palette[severity] ?? const Color(0xFFE5E5E5);
