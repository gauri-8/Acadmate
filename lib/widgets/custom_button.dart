import 'package:flutter/material.dart';

/// A reusable button widget that supports primary (filled) and outlined styles.
/// - [text]: The button label.
/// - [icon]: Optional leading icon widget.
/// - [onPressed]: Callback when pressed.
/// - [isPrimary]: If true, renders a filled primary button; otherwise outlined.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  final String text;
  final Widget? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final BorderRadius borderRadius = BorderRadius.circular(12);
    final EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      vertical: 14,
      horizontal: 16,
    );

    final TextStyle labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isPrimary ? colorScheme.onPrimary : colorScheme.primary,
    );

    final Widget label = Text(text, style: labelStyle);

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 10),
        ],
        label,
      ],
    );

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: contentPadding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          elevation: 0,
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: 1.2),
        padding: contentPadding,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      child: child,
    );
  }
}