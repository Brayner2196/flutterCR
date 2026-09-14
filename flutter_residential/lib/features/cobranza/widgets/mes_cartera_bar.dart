import 'package:flutter/material.dart';
import '../../../shared/widgets/mes_pildora.dart';
import '../utils/agrupador_cobranza.dart';

/// Barra de meses de la cartera morosa.
///
/// Misma pieza visual que la barra de Cobros (`MesSelectorBar`), pero con dos
/// diferencias que pide la cobranza: una píldora "Todos" al frente —porque al
/// cobrar interesa la deuda completa de una propiedad, no la de un mes— y un
/// contador de morosos en cada mes, para ver de un vistazo dónde está la bolsa.
class MesCarteraBar extends StatelessWidget {
  final List<GrupoMesCobranza> grupos;

  /// Clave del mes activo ('2026-09'). Null = todos.
  final String? seleccionado;

  final ValueChanged<String?> onSeleccionar;

  /// Total de cobros en deuda (badge de la píldora "Todos").
  final int total;

  /// Carga la cartera sin límite de meses. Null cuando ya está toda cargada.
  final VoidCallback? onVerAnteriores;

  const MesCarteraBar({
    super.key,
    required this.grupos,
    required this.seleccionado,
    required this.onSeleccionar,
    required this.total,
    this.onVerAnteriores,
  });

  @override
  Widget build(BuildContext context) {
    return RielPildoras(
      children: [
        MesPildora(
          label: 'Todos',
          activo: seleccionado == null,
          badge: total,
          onTap: () => onSeleccionar(null),
        ),
        for (final g in grupos)
          MesPildora(
            label: g.nombreCorto,
            activo: seleccionado == g.clave,
            badge: g.cantidad,
            onTap: () => onSeleccionar(g.clave),
          ),
        // La vista arranca con una ventana de meses para no traerse años de
        // cartera migrada en cada apertura; la deuda más vieja —que suele ser
        // la más grave— se pide a mano con esta píldora.
        if (onVerAnteriores != null)
          MesPildora(
            label: 'Anteriores',
            activo: false,
            icono: Icons.history,
            onTap: onVerAnteriores!,
          ),
      ],
    );
  }
}
