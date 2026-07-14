import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/propiedades/models/tipo_propiedad_nodo.dart';
import '../../../../features/propiedades/models/valor_tipo_propiedad.dart';
import '../../../../features/propiedades/providers/propiedad_provider.dart';
import '../../../../features/propiedades/services/propiedad_service.dart';
import '../../../../features/propiedades/widgets/valor_propiedad_dropdown.dart';

/// Nodo facturable con su ruta completa desde la raíz.
/// Ej: Apartamento → ruta = [Torre, Piso, Apartamento]
class _RutaFacturable {
  final List<TipoPropiedadNodo> ruta;

  const _RutaFacturable(this.ruta);

  TipoPropiedadNodo get nodo => ruta.last;
  String get etiqueta => nodo.nombre;

  @override
  bool operator ==(Object other) =>
      other is _RutaFacturable && other.nodo.id == nodo.id;

  @override
  int get hashCode => nodo.id.hashCode;
}

class UsuarioWizardStepPropiedad extends StatefulWidget {
  final String rol;

  const UsuarioWizardStepPropiedad({
    super.key,
    required this.rol,
  });

  @override
  UsuarioWizardStepPropiedadState createState() =>
      UsuarioWizardStepPropiedadState();
}

class UsuarioWizardStepPropiedadState
    extends State<UsuarioWizardStepPropiedad> {
  _RutaFacturable? _rutaSeleccionada;
  final List<TipoPropiedadNodo> _nivelesActivos = [];
  final List<ValorTipoPropiedad?> _valoresSeleccionados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropiedadProvider>().cargarTiposAdmin();
    });
  }

  // ── API pública para el wizard ─────────────────────────────────────────────

  bool get esValido {
    if (_rutaSeleccionada == null) return false;
    // Todos los niveles de la ruta deben tener un valor elegido del catálogo.
    return _valoresSeleccionados.isNotEmpty &&
        _valoresSeleccionados.every((v) => v != null);
  }

  /// Retorna el path como lista de {tipoId, valor} para enviar al backend.
  List<Map<String, dynamic>> buildPath() {
    final path = <Map<String, dynamic>>[];
    for (int i = 0; i < _nivelesActivos.length; i++) {
      if (i >= _valoresSeleccionados.length) break;
      final valor = _valoresSeleccionados[i];
      if (valor == null) break;
      path.add({'tipoId': _nivelesActivos[i].id, 'valor': valor.valor});
    }
    return path;
  }

  /// Retorna etiquetas legibles para el resumen. Ej: ['Torre: A', 'Piso: 3']
  List<String> buildPathLabels() {
    final parts = <String>[];
    for (int i = 0; i < _nivelesActivos.length; i++) {
      if (i >= _valoresSeleccionados.length) break;
      final valor = _valoresSeleccionados[i];
      if (valor == null) break;
      parts.add('${_nivelesActivos[i].nombre}: ${valor.valor}');
    }
    return parts;
  }

  // ── Lógica interna ─────────────────────────────────────────────────────────

  /// Recorre el árbol y devuelve una lista de rutas completas hacia cada nodo
  /// facturable. La ruta incluye todos los ancestros + el nodo facturable.
  List<_RutaFacturable> _encontrarFacturables(
    List<TipoPropiedadNodo> nodos, [
    List<TipoPropiedadNodo>? ancestros,
  ]) {
    final resultado = <_RutaFacturable>[];
    for (final nodo in nodos) {
      final ruta = [...?ancestros, nodo];
      if (nodo.esFacturable) {
        resultado.add(_RutaFacturable(ruta));
      }
      if (nodo.hijos.isNotEmpty) {
        resultado.addAll(_encontrarFacturables(nodo.hijos, ruta));
      }
    }
    return resultado;
  }

  /// Al seleccionar una ruta facturable, crea un controller por cada nivel
  /// de la ruta completa — todos los inputs aparecen a la vez.
  void _onRutaChanged(_RutaFacturable? ruta) {
    _nivelesActivos.clear();
    _valoresSeleccionados.clear();

    if (ruta != null) {
      for (final nodo in ruta.ruta) {
        _nivelesActivos.add(nodo);
        _valoresSeleccionados.add(null);
      }
    }
    setState(() => _rutaSeleccionada = ruta);
  }

  /// Al elegir un valor en el nivel [index], se limpian los niveles hijos (sus
  /// valores permitidos dependen del padre elegido).
  void _onValorSeleccionado(int index, ValorTipoPropiedad? valor) {
    _valoresSeleccionados[index] = valor;
    for (int j = index + 1; j < _valoresSeleccionados.length; j++) {
      _valoresSeleccionados[j] = null;
    }
    setState(() {});
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  InputDecoration _decor(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final provider = context.watch<PropiedadProvider>();
    final tiposArbol = provider.tiposArbol;
    final cargando = provider.loading;
    final esInquilino = widget.rol == 'INQUILINO';

    final bannerColor = esInquilino ? Colors.orange : Colors.teal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner contextual según rol
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: bannerColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  esInquilino
                      ? Icons.info_outline
                      : Icons.home_work_outlined,
                  color: bannerColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esInquilino ? 'Asociar a unidad existente' : 'Asignar unidad al propietario',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: bannerColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esInquilino
                            ? 'El inquilino se vincula a una propiedad ya registrada. No se creará ninguna unidad nueva.'
                            : 'Si la unidad no existe aún, se creará automáticamente en la jerarquía del conjunto.',
                        style: TextStyle(
                          fontSize: 12,
                          color: bannerColor.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Builder(builder: (_) {
            // Spinner mientras carga
            if (cargando) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            // Nodos facturables con su ruta completa desde la raíz
            final facturables = _encontrarFacturables(tiposArbol);

            if (facturables.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.home_work_outlined,
                          size: 44, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        tiposArbol.isEmpty
                            ? 'Sin tipos de propiedad configurados'
                            : 'Sin tipos de propiedad facturables',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tiposArbol.isEmpty
                            ? 'Configúralos desde la sección de Propiedades.'
                            : 'Marca al menos un tipo como facturable en Configuración → Tipos de propiedad.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dropdown muestra el nodo facturable (ej: Apartamento)
                DropdownButtonFormField<_RutaFacturable>(
                  initialValue: _rutaSeleccionada,
                  decoration: _decor(
                    'Tipo de propiedad',
                    Icons.home_work_outlined,
                    hint: 'Selecciona...',
                  ),
                  hint: const Text('Selecciona el tipo...'),
                  items: facturables
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.etiqueta),
                          ))
                      .toList(),
                  onChanged: _onRutaChanged,
                ),

                // Todos los niveles del árbol se muestran de golpe al seleccionar
                for (int i = 0; i < _nivelesActivos.length; i++) ...[
                  const SizedBox(height: 14),
                  _NivelField(
                    key: ValueKey(
                        'nivel_${_nivelesActivos[i].id}_${i == 0 ? 'raiz' : _valoresSeleccionados[i - 1]?.id}'),
                    nivel: i,
                    nodo: _nivelesActivos[i],
                    esPrimero: i == 0,
                    dependencyKey:
                        i == 0 ? 'raiz' : _valoresSeleccionados[i - 1]?.id,
                    loader: () => PropiedadService.getValoresAdmin(
                      _nivelesActivos[i].id,
                      parentValorId:
                          i == 0 ? null : _valoresSeleccionados[i - 1]?.id,
                    ),
                    onChanged: (v) => _onValorSeleccionado(i, v),
                  ),
                ],

                // Preview del path construido (aparece al elegir el primer nivel)
                if (_valoresSeleccionados.isNotEmpty &&
                    _valoresSeleccionados[0] != null) ...[
                  const SizedBox(height: 20),
                  _PathPreview(labels: buildPathLabels()),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Campo de nivel con decoración por profundidad ────────────────────────────

class _NivelField extends StatelessWidget {
  final int nivel;
  final TipoPropiedadNodo nodo;
  final bool esPrimero;
  final Object? dependencyKey;
  final ValoresLoader loader;
  final ValueChanged<ValorTipoPropiedad?> onChanged;

  const _NivelField({
    super.key,
    required this.nivel,
    required this.nodo,
    required this.esPrimero,
    required this.dependencyKey,
    required this.loader,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colores = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
    ];
    final color = colores[nivel % colores.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Conector visual de jerarquía
        if (!esPrimero)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: cs.outlineVariant,
            ),
          ),
        // Chip del tipo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            nodo.nombre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Dropdown con búsqueda (solo valores del catálogo)
        Expanded(
          child: ValorPropiedadDropdown(
            label: nodo.nombre,
            color: color,
            dependencyKey: dependencyKey,
            loader: loader,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Preview del path construido ──────────────────────────────────────────────

class _PathPreview extends StatelessWidget {
  final List<String> labels;

  const _PathPreview({required this.labels});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  if (i > 0)
                    Icon(Icons.chevron_right,
                        size: 14, color: cs.onSurfaceVariant),
                  Text(
                    labels[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.check_circle_outline,
              size: 16, color: Colors.teal),
        ],
      ),
    );
  }
}
