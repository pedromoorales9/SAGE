import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class AppleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  
  const AppleButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Button styling based on primary/secondary status
    final backgroundColor = isPrimary
        ? themeProvider.primaryButtonColor(context)
        : themeProvider.secondaryButtonColor(context);
    
    final textColor = isPrimary
        ? Colors.white
        : themeProvider.textColor(context);
    
    // Usando un botón simple con ConstrainedBox para evitar problemas de layout
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 50,
      ),
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          backgroundColor: onPressed == null
              ? backgroundColor.withOpacity(0.5)
              : backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: const Size(88, 50),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}