import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class OnboardingItem {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String description;

  const OnboardingItem({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.description,
  });
}

const List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    icon: Icons.apartment_outlined,
    background: AppColors.bgBlue,
    foreground: AppColors.blue,
    title: 'Tu conjunto, en un solo lugar',
    description:
        'Administra propiedades, residentes y unidades de tu conjunto residencial desde una unica aplicacion segura.',
  ),
  OnboardingItem(
    icon: Icons.payments_outlined,
    background: AppColors.bgGreen,
    foreground: AppColors.green,
    title: 'Cobros y pagos sin complicaciones',
    description:
        'Genera cobros mensuales, registra pagos y consulta el estado de cuenta de cada propiedad sin papeleos.',
  ),
  OnboardingItem(
    icon: Icons.groups_outlined,
    background: AppColors.bgPurple,
    foreground: AppColors.purple,
    title: 'Pensado para tu rol',
    description:
        'Administrador del conjunto, residente, vigilante: cada perfil ve la informacion que le corresponde.',
  ),
];
