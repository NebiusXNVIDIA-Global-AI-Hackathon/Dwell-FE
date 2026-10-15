import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'email_domain_dropdown.dart';

/// Labels sit outside these fields, so an outline's floating-label gap is unused.
InputDecoration emailInputDecoration(
  InputDecoration decoration,
  EdgeInsets padding,
) {
  InputBorder? withoutGap(InputBorder? border) =>
      border is OutlineInputBorder ? border.copyWith(gapPadding: 0) : border;
  return decoration.copyWith(
    contentPadding: padding,
    border: withoutGap(decoration.border),
    enabledBorder: withoutGap(decoration.enabledBorder),
    focusedBorder: withoutGap(decoration.focusedBorder),
    disabledBorder: withoutGap(decoration.disabledBorder),
    errorBorder: withoutGap(decoration.errorBorder),
    focusedErrorBorder: withoutGap(decoration.focusedErrorBorder),
  );
}

/// Fit the controls inside the available width; never scroll the email group.
class EmailInputRow extends StatelessWidget {
  const EmailInputRow({
    super.key,
    required this.inputBuilder,
    required this.dropdown,
  });
  final TextField Function(EdgeInsets padding) inputBuilder;
  final EmailDomainDropdown dropdown;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final theme = Theme.of(context);
    final domainStyle = theme.textTheme.labelLarge!.copyWith(fontSize: 16);
    final hintStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 16,
      height: 1.2,
    );
    final atStyle = theme.textTheme.bodyLarge!.copyWith(
      fontSize: 20,
      color: const Color(0xFF606060),
    );
    double measure(String value, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textScaler: scaler,
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    final domainText = EmailDomainDropdown.domains
        .map((value) => measure(value, domainStyle))
        .reduce(math.max);
    final hintWidth = measure('Enter your email', hintStyle) + 8;
    final atText = measure('@', atStyle);
    final height = math.max(56.0, scaler.scale(16) * 1.2 + 36);
    // Field padding, domain padding, arrow gap, total spacing around @.
    const spacings = [
      (20.0, 8.0, 8.0, 16.0),
      (8.0, 4.0, 4.0, 8.0),
      (2.0, 2.0, 2.0, 2.0),
    ];
    double domainWidth((double, double, double, double) spacing) =>
        domainText + spacing.$2 * 2 + spacing.$3 + 18 + 2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final inline = spacings.where(
          (s) =>
              hintWidth + s.$1 * 2 + atText + s.$4 + domainWidth(s) <=
              available,
        );
        final stacked = inline.isEmpty && scaler.scale(16) > 16;
        final spacing = stacked
            ? spacings.firstWhere(
                (s) => atText + s.$4 + domainWidth(s) <= available,
                orElse: () => spacings.last,
              )
            : inline.isEmpty
            ? spacings.last
            : inline.first;
        final inputPadding = stacked
            ? spacings
                  .firstWhere(
                    (s) => hintWidth + s.$1 * 2 <= available,
                    orElse: () => spacings.last,
                  )
                  .$1
            : spacing.$1;
        final input = SizedBox(
          height: height,
          child: inputBuilder(
            EdgeInsets.symmetric(horizontal: inputPadding, vertical: 18),
          ),
        );
        final control = dropdown.withLayout(
          horizontalPadding: spacing.$2,
          arrowGap: spacing.$3,
          minimumMenuWidth: domainText + 48,
        );
        Widget at() => SizedBox(
          width: atText + spacing.$4,
          child: Center(
            child: Text('@', style: atStyle, maxLines: 1, softWrap: false),
          ),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              input,
              const SizedBox(height: 10),
              SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    at(),
                    Expanded(child: control),
                  ],
                ),
              ),
            ],
          );
        }
        return SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: input),
              at(),
              SizedBox(width: domainWidth(spacing), child: control),
            ],
          ),
        );
      },
    );
  }
}
