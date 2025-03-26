import 'package:flutter/material.dart';

/// Utilitario para manejar el diseño responsivo en la aplicación
class Responsive {
  /// Comprueba si el ancho actual de la pantalla es de un dispositivo móvil
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  /// Comprueba si el ancho actual de la pantalla es de una tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  /// Comprueba si el ancho actual de la pantalla es de escritorio
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Devuelve el padding horizontal adecuado según el tamaño de la pantalla
  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 24.0;
    if (isTablet(context)) return 16.0;
    return 8.0;
  }

  /// Devuelve el ancho adecuado para las tarjetas según el tamaño de la pantalla
  static double cardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isDesktop(context)) return width * 0.3;
    if (isTablet(context)) return width * 0.45;
    return width * 0.9;
  }

  /// Devuelve el número de columnas adecuado para una cuadrícula según el tamaño de la pantalla
  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Devuelve el factor de escala adecuado para los textos según el tamaño de la pantalla
  static double textScaleFactor(BuildContext context) {
    if (isDesktop(context)) return 1.2;
    if (isTablet(context)) return 1.1;
    return 1.0;
  }

  /// Devuelve el widget apropiado según el tipo de dispositivo
  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }
}
