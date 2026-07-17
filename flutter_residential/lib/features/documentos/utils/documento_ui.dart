import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Helpers de presentación reutilizables del módulo Documentos.
/// Centraliza labels, íconos y colores por categoría/tipo para no repetirlos
/// en cada pantalla.
class DocumentoUi {
  DocumentoUi._();

  // ─── Categorías ──────────────────────────────────────────────────────────

  /// Categorías disponibles (valor backend). null = "Todas" en filtros.
  static const List<String> categorias = [
    'REGLAMENTO',
    'ACTAS',
    'FINANCIERO',
    'COMUNICADOS',
    'OTROS',
  ];

  static String labelCategoria(String c) {
    switch (c) {
      case 'REGLAMENTO':
        return 'Reglamento';
      case 'ACTAS':
        return 'Actas';
      case 'FINANCIERO':
        return 'Financiero';
      case 'COMUNICADOS':
        return 'Comunicados';
      case 'OTROS':
        return 'Otros';
      default:
        return c;
    }
  }

  static IconData iconoCategoria(String c) {
    switch (c) {
      case 'REGLAMENTO':
        return Icons.gavel_outlined;
      case 'ACTAS':
        return Icons.description_outlined;
      case 'FINANCIERO':
        return Icons.account_balance_wallet_outlined;
      case 'COMUNICADOS':
        return Icons.campaign_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  /// Par (fondo, acento) por categoría, tomado de la paleta del proyecto.
  static (Color, Color) coloresCategoria(String c) {
    switch (c) {
      case 'REGLAMENTO':
        return (AppColors.bgBlue, AppColors.blue);
      case 'ACTAS':
        return (AppColors.bgTeal, AppColors.teal);
      case 'FINANCIERO':
        return (AppColors.bgGreen, AppColors.green);
      case 'COMUNICADOS':
        return (AppColors.bgYellow, AppColors.yellow);
      default:
        return (AppColors.bgSlate, AppColors.blue);
    }
  }

  // ─── Tipos de archivo ──────────────────────────────────────────────────────

  static IconData iconoTipo(String tipo) {
    switch (tipo) {
      case 'PDF':
        return Icons.picture_as_pdf_outlined;
      case 'WORD':
        return Icons.article_outlined;
      case 'EXCEL':
        return Icons.table_chart_outlined;
      case 'IMAGEN':
        return Icons.image_outlined;
      case 'VIDEO':
        return Icons.videocam_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // ─── Formato de tamaño ─────────────────────────────────────────────────────

  static String formatoTamano(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}
