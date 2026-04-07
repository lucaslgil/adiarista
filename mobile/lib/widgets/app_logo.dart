import 'package:flutter/material.dart';

/// Widget helper para exibir a logomarca do aDiarista
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isDarkMode;
  final LogoVariant variant;

  const AppLogo({
    Key? key,
    this.width,
    this.height,
    this.isDarkMode = false,
    this.variant = LogoVariant.principal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String assetPath = _getLogoPath();

    // Fallback para texto se a logo não existir ainda
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Placeholder temporário enquanto não há logo
        return _buildPlaceholder();
      },
    );
  }

  String _getLogoPath() {
    switch (variant) {
      case LogoVariant.principal:
        return isDarkMode
            ? 'assets/logo/logo_white.png'
            : 'assets/logo/logo.png';
      case LogoVariant.icon:
        return 'assets/logo/logo_icon.png';
      case LogoVariant.horizontal:
        return 'assets/logo/logo_horizontal.png';
      case LogoVariant.splash:
        return 'assets/logo/logo_splash.png';
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width ?? 120,
      height: height ?? 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6200EE), Color(0xFF03DAC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'aD',
          style: TextStyle(
            color: Colors.white,
            fontSize: (width ?? 120) * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Variantes disponíveis da logo
enum LogoVariant {
  principal, // Logo completa
  icon, // Apenas ícone
  horizontal, // Logo horizontal com nome
  splash, // Logo para splash screen
}
