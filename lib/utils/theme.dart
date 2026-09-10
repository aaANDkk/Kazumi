import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SuperellipseInputBorder extends OutlineInputBorder {
  const SuperellipseInputBorder({
    super.borderSide = const BorderSide(),
    super.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.gapPadding = 4.0,
  });

  @override
  SuperellipseInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) {
    return SuperellipseInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  SuperellipseInputBorder scale(double t) {
    return SuperellipseInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OutlineInputBorder) {
      return SuperellipseInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
        gapPadding: a.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is OutlineInputBorder) {
      return SuperellipseInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
        gapPadding: b.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return RoundedSuperellipseBorder(
      borderRadius: borderRadius,
      side: borderSide,
    ).getInnerPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return RoundedSuperellipseBorder(
      borderRadius: borderRadius,
      side: borderSide,
    ).getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0.0) {
      return;
    }

    final paint = Paint()
      ..color = borderSide.color
      ..strokeWidth = borderSide.width
      ..style = PaintingStyle.stroke;

    final border = RoundedSuperellipseBorder(
      borderRadius: borderRadius,
      side: borderSide,
    );
    final outerPath = border.getOuterPath(rect);

    if (gapStart == null || gapExtent <= 0.0 || gapPercentage <= 0.0) {
      canvas.drawPath(outerPath, paint);
      return;
    }

    final double extent = gapExtent * gapPercentage.clamp(0.0, 1.0);
    final double gapLeft;
    final double gapRight;
    if (textDirection == TextDirection.rtl) {
      gapLeft = (gapStart - extent - gapPadding).clamp(rect.left, rect.right);
      gapRight = (gapStart + gapPadding).clamp(rect.left, rect.right);
    } else {
      gapLeft = (gapStart - gapPadding).clamp(rect.left, rect.right);
      gapRight = (gapStart + extent + gapPadding).clamp(rect.left, rect.right);
    }

    final gapRect = Rect.fromLTRB(
      gapLeft,
      rect.top - borderSide.width - 4.0,
      gapRight,
      rect.top + borderSide.width + 4.0,
    );

    canvas.save();
    canvas.clipRect(gapRect, clipOp: ui.ClipOp.difference);
    canvas.drawPath(outerPath, paint);
    canvas.restore();
  }
}

ThemeData applyAppTheme(ThemeData theme) {
  return theme.copyWith(
    cardTheme: const CardThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    searchBarTheme: const SearchBarThemeData(
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
    ),
    searchViewTheme: const SearchViewThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: SuperellipseInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      enabledBorder: SuperellipseInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      focusedBorder: SuperellipseInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorShape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorShape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationDrawerTheme: const NavigationDrawerThemeData(
      indicatorShape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    datePickerTheme: const DatePickerThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    timePickerTheme: const TimePickerThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: ShapeDecoration(
        color: Colors.black87,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
  );
}

ThemeData oledDarkTheme(ThemeData defaultDarkTheme) {
  return defaultDarkTheme.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: defaultDarkTheme.colorScheme.copyWith(
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    ),
  );
}

