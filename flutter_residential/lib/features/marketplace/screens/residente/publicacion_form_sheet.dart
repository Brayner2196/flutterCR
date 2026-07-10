import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/publicacion_model.dart';
import '../../services/publicacion_service.dart';

// ─── Constantes ────────────────────────────────────────────────────────────────

const _kMetodosPago = [
  ('EFECTIVO',      'Efectivo',      Icons.payments_outlined),
  ('NEQUI',         'Nequi',         Icons.account_balance_outlined),
  ('DAVIPLATA',     'Daviplata',     Icons.account_balance_outlined),
  ('TRANSFERENCIA', 'Transferencia', Icons.swap_horiz_outlined),
  ('BANCOLOMBIA',   'Bancolombia',   Icons.account_balance_outlined),
];

const _kPasos = [
  (Icons.storefront_outlined,    'Lo esencial',      'Título, precio y categoría'),
  (Icons.tune_outlined,          'Detalles',         'Descripción, marca y stock'),
  (Icons.local_shipping_outlined,'Entrega y pago',   'Domicilio y métodos de pago'),
  (Icons.fact_check_outlined,    'Confirmar',        'Revisa y publica'),
];

// ─── Widget principal ──────────────────────────────────────────────────────────

class PublicacionFormSheet extends StatefulWidget {
  final PublicacionModel? publicacion;
  final VoidCallback onGuardado;
  final int? propiedadId;

  const PublicacionFormSheet({
    super.key,
    this.publicacion,
    required this.onGuardado,
    this.propiedadId,
  });

  @override
  State<PublicacionFormSheet> createState() => _PublicacionFormSheetState();
}

class _PublicacionFormSheetState extends State<PublicacionFormSheet> {
  // Controladores de página
  final _pageCtrl = PageController();
  int _paso = 0;

  // Form keys por paso
  final _form0 = GlobalKey<FormState>();
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();

  // Campos
  final _tituloCtrl   = TextEditingController();
  final _precioCtrl   = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _marcaCtrl    = TextEditingController();
  final _stockCtrl    = TextEditingController();
  final _contactoCtrl = TextEditingController();

  String?      _categoria;
  bool         _aceptaDomicilio = false;
  bool         _manejaStock     = false;
  List<String> _metodosPago     = [];
  bool         _guardando       = false;

  bool get _esEdicion => widget.publicacion != null;

  @override
  void initState() {
    super.initState();
    final p = widget.publicacion;
    if (p != null) {
      _tituloCtrl.text   = p.titulo;
      _precioCtrl.text   = p.precio.toStringAsFixed(
          p.precio.truncateToDouble() == p.precio ? 0 : 2);
      _descCtrl.text     = p.descripcion ?? '';
      _marcaCtrl.text    = p.marca ?? '';
      _contactoCtrl.text = p.contacto ?? '';
      _categoria         = p.categoria;
      _aceptaDomicilio   = p.aceptaDomicilio;
      _metodosPago       = List<String>.from(p.metodosPago);
      _manejaStock       = p.stock != null;
      if (p.stock != null) _stockCtrl.text = p.stock.toString();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _tituloCtrl.dispose();
    _precioCtrl.dispose();
    _descCtrl.dispose();
    _marcaCtrl.dispose();
    _stockCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  // ─── Navegación ─────────────────────────────────────────────────────────────

  bool _validarPasoActual() {
    if (_paso == 0) {
      if (!(_form0.currentState?.validate() ?? false)) return false;
      if (_categoria == null) {
        _mostrarError('Selecciona una categoría');
        return false;
      }
      return true;
    }
    if (_paso == 1) {
      if (!(_form1.currentState?.validate() ?? false)) return false;
      if (_manejaStock) {
        final s = int.tryParse(_stockCtrl.text.trim());
        if (s == null || s < 0) {
          _mostrarError('Ingresa una cantidad de stock válida (0 o más)');
          return false;
        }
      }
      return true;
    }
    if (_paso == 2) return _form2.currentState?.validate() ?? true;
    return true;
  }

  void _avanzar() {
    if (!_validarPasoActual()) return;
    if (_paso < 3) {
      setState(() => _paso++);
      _pageCtrl.animateToPage(
        _paso,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _retroceder() {
    if (_paso > 0) {
      setState(() => _paso--);
      _pageCtrl.animateToPage(
        _paso,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ─── Publicar ───────────────────────────────────────────────────────────────

  Future<void> _publicar() async {
    setState(() => _guardando = true);

    final data = <String, dynamic>{
      'titulo':          _tituloCtrl.text.trim(),
      'descripcion':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'precio':          double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0.0,
      'categoria':       _categoria,
      'contacto':        _contactoCtrl.text.trim().isEmpty ? null : _contactoCtrl.text.trim(),
      'marca':           _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
      'stock':           _manejaStock ? int.tryParse(_stockCtrl.text.trim()) : null,
      'aceptaDomicilio': _aceptaDomicilio,
      'metodosPago':     _metodosPago,
      if (!_esEdicion && widget.propiedadId != null)
        'propiedadId': widget.propiedadId,
    };

    try {
      if (!_esEdicion) {
        await PublicacionService.crear(data);
      } else {
        await PublicacionService.actualizar(widget.publicacion!.id, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onGuardado();
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final mq    = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: mq.size.height * 0.92,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        child: Column(
          children: [
            // ── Handle ───────────────────────────────────────────────────────
            _Handle(),

            // ── Header: título wizard + stepper ──────────────────────────────
            _WizardHeader(paso: _paso, esEdicion: _esEdicion),

            const Divider(height: 1),

            // ── Páginas ───────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Paso0Esencial(
                    formKey:      _form0,
                    tituloCtrl:   _tituloCtrl,
                    precioCtrl:   _precioCtrl,
                    categoria:    _categoria,
                    onCategoria:  (v) => setState(() => _categoria = v),
                  ),
                  _Paso1Detalles(
                    formKey:      _form1,
                    descCtrl:     _descCtrl,
                    marcaCtrl:    _marcaCtrl,
                    stockCtrl:    _stockCtrl,
                    manejaStock:  _manejaStock,
                    onManejaStock: (v) => setState(() {
                      _manejaStock = v;
                      if (!v) _stockCtrl.clear();
                    }),
                  ),
                  _Paso2EntregaPago(
                    formKey:         _form2,
                    contactoCtrl:    _contactoCtrl,
                    aceptaDomicilio: _aceptaDomicilio,
                    onDomicilio:     (v) => setState(() => _aceptaDomicilio = v),
                    metodosPago:     _metodosPago,
                    onToggleMetodo:  (m) => setState(() {
                      if (_metodosPago.contains(m)) {
                        _metodosPago.remove(m);
                      } else {
                        _metodosPago.add(m);
                      }
                    }),
                  ),
                  _Paso3Resumen(
                    titulo:          _tituloCtrl.text,
                    descripcion:     _descCtrl.text,
                    precio:          double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0,
                    categoria:       _categoria ?? '',
                    marca:           _marcaCtrl.text,
                    contacto:        _contactoCtrl.text,
                    stock:           _manejaStock ? int.tryParse(_stockCtrl.text) : null,
                    aceptaDomicilio: _aceptaDomicilio,
                    metodosPago:     _metodosPago,
                    esEdicion:       _esEdicion,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Barra de navegación inferior ─────────────────────────────────
            _BarraNavegacion(
              paso:       _paso,
              guardando:  _guardando,
              esEdicion:  _esEdicion,
              onAtras:    _retroceder,
              onSiguiente: _avanzar,
              onPublicar: _publicar,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Handle ────────────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Wizard Header ────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final int paso;
  final bool esEdicion;
  const _WizardHeader({required this.paso, required this.esEdicion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título general
          Text(
            esEdicion ? 'Editar publicación' : 'Nueva publicación',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Stepper visual
          Row(
            children: List.generate(_kPasos.length, (i) {
              final estado = i < paso
                  ? _StepEstado.completado
                  : i == paso
                      ? _StepEstado.activo
                      : _StepEstado.pendiente;
              return Expanded(
                child: _StepIndicator(
                  numero: i + 1,
                  label: _kPasos[i].$1 == Icons.fact_check_outlined ? 'Confirmar' : _kPasos[i].$2,
                  estado: estado,
                  esUltimo: i == _kPasos.length - 1,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum _StepEstado { completado, activo, pendiente }

class _StepIndicator extends StatelessWidget {
  final int numero;
  final String label;
  final _StepEstado estado;
  final bool esUltimo;
  const _StepIndicator({
    required this.numero,
    required this.label,
    required this.estado,
    required this.esUltimo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color circleBg;
    final Color circleFg;
    final Color lineBg;
    final FontWeight labelWeight;
    final Color labelColor;

    switch (estado) {
      case _StepEstado.completado:
        circleBg   = AppColors.ok;
        circleFg   = Colors.white;
        lineBg     = AppColors.ok;
        labelWeight = FontWeight.w500;
        labelColor  = AppColors.ok;
      case _StepEstado.activo:
        circleBg   = cs.primary;
        circleFg   = cs.onPrimary;
        lineBg     = cs.outline;
        labelWeight = FontWeight.w700;
        labelColor  = cs.primary;
      case _StepEstado.pendiente:
        circleBg   = cs.surfaceContainerHighest;
        circleFg   = cs.onSurfaceVariant;
        lineBg     = cs.outline.withValues(alpha: 0.4);
        labelWeight = FontWeight.w400;
        labelColor  = cs.onSurfaceVariant;
    }

    return Column(
      children: [
        Row(
          children: [
            // Círculo
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
              child: Center(
                child: estado == _StepEstado.completado
                    ? Icon(Icons.check, size: 15, color: circleFg)
                    : Text('$numero',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: circleFg)),
              ),
            ),
            // Línea conectora
            if (!esUltimo)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: lineBg,
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Align(
          alignment: Alignment.centerLeft,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: labelWeight,
              color: labelColor,
              fontFamily: 'GoogleSans',
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}

// ─── Barra de navegación ───────────────────────────────────────────────────────

class _BarraNavegacion extends StatelessWidget {
  final int paso;
  final bool guardando;
  final bool esEdicion;
  final VoidCallback onAtras;
  final VoidCallback onSiguiente;
  final VoidCallback onPublicar;

  const _BarraNavegacion({
    required this.paso,
    required this.guardando,
    required this.esEdicion,
    required this.onAtras,
    required this.onSiguiente,
    required this.onPublicar,
  });

  @override
  Widget build(BuildContext context) {
    final esUltimo = paso == 3;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            // Botón Atrás / Cancelar
            OutlinedButton.icon(
              onPressed: guardando ? null : onAtras,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
              label: Text(paso == 0 ? 'Cancelar' : 'Atrás'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Siguiente / Publicar
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: esUltimo
                    ? FilledButton.icon(
                        key: const ValueKey('publicar'),
                        onPressed: guardando ? null : onPublicar,
                        icon: guardando
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(
                                esEdicion ? Icons.save_outlined : Icons.upload_rounded,
                                size: 18),
                        label: Text(
                          guardando
                              ? 'Guardando…'
                              : esEdicion
                                  ? 'Guardar cambios'
                                  : 'Publicar ahora',
                        ),
                      )
                    : FilledButton.icon(
                        key: const ValueKey('siguiente'),
                        onPressed: onSiguiente,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                        label: const Text('Siguiente'),
                        style: FilledButton.styleFrom(
                          iconColor: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASO 0 — Lo esencial: Título, Categoría, Precio
// ─────────────────────────────────────────────────────────────────────────────

class _Paso0Esencial extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tituloCtrl;
  final TextEditingController precioCtrl;
  final String? categoria;
  final ValueChanged<String?> onCategoria;

  const _Paso0Esencial({
    required this.formKey,
    required this.tituloCtrl,
    required this.precioCtrl,
    required this.categoria,
    required this.onCategoria,
  });

  @override
  Widget build(BuildContext context) {
    return _PasoScroll(
      pasoIndex: 0,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            TextFormField(
              controller: tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ej: Litro de leche entera, Silla de oficina…',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              maxLength: 120,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 4),

            // Precio
            TextFormField(
              controller: precioCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio *',
                prefixText: '\$ ',
                prefixIcon: Icon(Icons.attach_money_rounded),
                hintText: '0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El precio es obligatorio';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n < 0) return 'Precio inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Categoría
            _SubLabel(
              icon: Icons.category_outlined,
              label: 'Categoría *',
              sublabel: 'Elige la que mejor describe tu producto o servicio',
            ),
            const SizedBox(height: 12),
            _CategoriaGrid(
              seleccionada: categoria,
              onSeleccionar: onCategoria,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaGrid extends StatelessWidget {
  final String? seleccionada;
  final ValueChanged<String?> onSeleccionar;

  const _CategoriaGrid({required this.seleccionada, required this.onSeleccionar});

  static const _items = [
    ('ALIMENTOS',   'Alimentos',   Icons.restaurant_outlined,   AppColors.bgGreen,   AppColors.green),
    ('SERVICIOS',   'Servicios',   Icons.build_outlined,        AppColors.bgBlue,    AppColors.blue),
    ('MASCOTAS',    'Mascotas',    Icons.pets_outlined,          AppColors.bgYellow,  AppColors.yellow),
    ('ELECTRONICA', 'Electrónica', Icons.devices_outlined,       AppColors.bgPurple,  AppColors.purple),
    ('MUEBLES',     'Muebles',     Icons.chair_outlined,         AppColors.bgOrange,  AppColors.orange),
    ('ROPA',        'Ropa',        Icons.checkroom_outlined,     AppColors.bgTeal,    AppColors.teal),
    ('OTROS',       'Otros',       Icons.category_outlined,      AppColors.neutralSoft, AppColors.textLoLight),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _items.map((item) {
        final sel = seleccionada == item.$1;
        return GestureDetector(
          onTap: () => onSeleccionar(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? item.$5.withValues(alpha: 0.15) : cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: sel ? item.$5 : cs.outline.withValues(alpha: 0.5),
                width: sel ? 1.8 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$3, size: 17,
                    color: sel ? item.$5 : cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(item.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? item.$5 : cs.onSurface,
                    )),
                if (sel) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle_rounded, size: 14, color: item.$5),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASO 1 — Detalles: Descripción, Marca, Stock
// ─────────────────────────────────────────────────────────────────────────────

class _Paso1Detalles extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descCtrl;
  final TextEditingController marcaCtrl;
  final TextEditingController stockCtrl;
  final bool manejaStock;
  final ValueChanged<bool> onManejaStock;

  const _Paso1Detalles({
    required this.formKey,
    required this.descCtrl,
    required this.marcaCtrl,
    required this.stockCtrl,
    required this.manejaStock,
    required this.onManejaStock,
  });

  @override
  Widget build(BuildContext context) {

    return _PasoScroll(
      pasoIndex: 1,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción
            TextFormField(
              controller: descCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Estado, características, condiciones de venta…',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.notes_rounded),
                ),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 6,
              maxLength: 1000,
            ),
            const SizedBox(height: 4),

            // Marca
            TextFormField(
              controller: marcaCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Marca (opcional)',
                hintText: 'Ej: Alquería, Samsung, Ikea…',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),

            // Stock
            _SubLabel(
              icon: Icons.inventory_2_outlined,
              label: 'Control de stock',
              sublabel: 'Indica cuántas unidades tienes disponibles',
            ),
            const SizedBox(height: 8),
            _StockSelector(
              manejaStock:  manejaStock,
              stockCtrl:    stockCtrl,
              onManeja:     onManejaStock,
            ),
          ],
        ),
      ),
    );
  }
}

class _StockSelector extends StatelessWidget {
  final bool manejaStock;
  final TextEditingController stockCtrl;
  final ValueChanged<bool> onManeja;

  const _StockSelector({
    required this.manejaStock,
    required this.stockCtrl,
    required this.onManeja,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Toggle card
        GestureDetector(
          onTap: () => onManeja(!manejaStock),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: manejaStock
                  ? cs.primary.withValues(alpha: 0.07)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: manejaStock ? cs.primary : cs.outline.withValues(alpha: 0.5),
                width: manejaStock ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  manejaStock
                      ? Icons.inventory_2_rounded
                      : Icons.inventory_2_outlined,
                  color: manejaStock ? cs.primary : cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Indicar unidades disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: manejaStock ? cs.primary : cs.onSurface,
                        ),
                      ),
                      Text(
                        manejaStock
                            ? 'Los compradores verán cuántas quedan'
                            : 'Sin control de stock visible',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Switch(value: manejaStock, onChanged: onManeja),
              ],
            ),
          ),
        ),
        // Campo de cantidad
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: manejaStock
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: stockCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Unidades disponibles',
                      hintText: '0 = agotado',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASO 2 — Entrega y pago
// ─────────────────────────────────────────────────────────────────────────────

class _Paso2EntregaPago extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController contactoCtrl;
  final bool aceptaDomicilio;
  final ValueChanged<bool> onDomicilio;
  final List<String> metodosPago;
  final ValueChanged<String> onToggleMetodo;

  const _Paso2EntregaPago({
    required this.formKey,
    required this.contactoCtrl,
    required this.aceptaDomicilio,
    required this.onDomicilio,
    required this.metodosPago,
    required this.onToggleMetodo,
  });

  @override
  Widget build(BuildContext context) {

    return _PasoScroll(
      pasoIndex: 2,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Domicilio
            _SubLabel(
              icon: Icons.delivery_dining_outlined,
              label: 'Entrega a domicilio',
              sublabel: '¿Ofreces entrega dentro del conjunto?',
            ),
            const SizedBox(height: 10),
            _DomicilioToggle(
              acepta: aceptaDomicilio,
              onCambio: onDomicilio,
            ),
            const SizedBox(height: 24),

            // Métodos de pago
            _SubLabel(
              icon: Icons.payments_outlined,
              label: 'Métodos de pago',
              sublabel: 'Selecciona todos los que aceptas',
            ),
            const SizedBox(height: 12),
            _MetodosPagoGrid(
              seleccionados: metodosPago,
              onToggle: onToggleMetodo,
            ),
            const SizedBox(height: 24),

            // Contacto
            _SubLabel(
              icon: Icons.contact_phone_outlined,
              label: 'Dato de contacto',
              sublabel: 'Opcional: teléfono, WhatsApp o cualquier indicación',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: contactoCtrl,
              decoration: const InputDecoration(
                labelText: 'Contacto (opcional)',
                hintText: 'Ej: 310 123 4567 o "Enviar mensaje por la app"',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              maxLength: 100,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ),
    );
  }
}

class _DomicilioToggle extends StatelessWidget {
  final bool acepta;
  final ValueChanged<bool> onCambio;
  const _DomicilioToggle({required this.acepta, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onCambio(!acepta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: acepta ? AppColors.bgBlue : cs.surfaceContainerHighest.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: acepta ? AppColors.blue : cs.outline.withValues(alpha:0.5),
            width: acepta ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: acepta ? AppColors.bgBlue : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: acepta ? AppColors.blue.withValues(alpha:0.4) : cs.outline.withValues(alpha:0.3),
                ),
              ),
              child: Icon(
                Icons.delivery_dining_rounded,
                color: acepta ? AppColors.blue : cs.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    acepta ? '¡Ofreces domicilio!' : 'Sin domicilio',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: acepta ? AppColors.blue : cs.onSurface,
                    ),
                  ),
                  Text(
                    acepta
                        ? 'Los compradores podrán pedirte envío a su puerta'
                        : 'Solo recogida en tu ubicación',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Switch(value: acepta, onChanged: onCambio),
          ],
        ),
      ),
    );
  }
}

class _MetodosPagoGrid extends StatelessWidget {
  final List<String> seleccionados;
  final ValueChanged<String> onToggle;
  const _MetodosPagoGrid({required this.seleccionados, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kMetodosPago.map((m) {
        final sel = seleccionados.contains(m.$1);
        return GestureDetector(
          onTap: () => onToggle(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: sel ? cs.primaryContainer : cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: sel ? cs.primary : cs.outline.withValues(alpha:0.5),
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(m.$3, size: 16,
                    color: sel ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(m.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? cs.primary : cs.onSurface,
                    )),
                if (sel) ...[
                  const SizedBox(width: 5),
                  Icon(Icons.check_circle_rounded, size: 13, color: cs.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PASO 3 — Resumen y confirmación
// ─────────────────────────────────────────────────────────────────────────────

class _Paso3Resumen extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final double precio;
  final String categoria;
  final String marca;
  final String contacto;
  final int? stock;
  final bool aceptaDomicilio;
  final List<String> metodosPago;
  final bool esEdicion;

  const _Paso3Resumen({
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.marca,
    required this.contacto,
    required this.stock,
    required this.aceptaDomicilio,
    required this.metodosPago,
    required this.esEdicion,
  });

  String get _precioFormateado =>
      '\$${precio.toStringAsFixed(precio.truncateToDouble() == precio ? 0 : 2)}';

  String get _categoriaLegible {
    const mapa = {
      'ALIMENTOS':   'Alimentos',
      'SERVICIOS':   'Servicios',
      'MASCOTAS':    'Mascotas',
      'ELECTRONICA': 'Electrónica',
      'MUEBLES':     'Muebles',
      'ROPA':        'Ropa',
      'OTROS':       'Otros',
    };
    return mapa[categoria] ?? categoria;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return _PasoScroll(
      pasoIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de confirmación ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgGreen,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.ok.withValues(alpha:0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.ok.withValues(alpha:0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fact_check_rounded,
                      color: AppColors.ok, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esEdicion ? 'Todo listo para guardar' : 'Todo listo para publicar',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ok,
                        ),
                      ),
                      Text(
                        esEdicion
                            ? 'Revisa los cambios antes de confirmar'
                            : 'Revisa que todo esté correcto',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.ok.withValues(alpha:0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Vista previa de la publicación ─────────────────────────────
          Text('Vista previa',
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          _TarjetaPreview(
            titulo:          titulo,
            precio:          _precioFormateado,
            categoria:       _categoriaLegible,
            marca:           marca,
            descripcion:     descripcion,
            stock:           stock,
            aceptaDomicilio: aceptaDomicilio,
            metodosPago:     metodosPago,
          ),
          const SizedBox(height: 20),

          // ── Detalles colapsados ─────────────────────────────────────────
          Text('Información completa',
              style: theme.textTheme.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 10),
          _ResumenItem(icon: Icons.title_rounded,        label: 'Título',         valor: titulo.isNotEmpty ? titulo : '—'),
          _ResumenItem(icon: Icons.attach_money_rounded, label: 'Precio',         valor: _precioFormateado),
          _ResumenItem(icon: Icons.category_outlined,    label: 'Categoría',      valor: _categoriaLegible),
          if (marca.isNotEmpty)
            _ResumenItem(icon: Icons.label_outline_rounded, label: 'Marca',       valor: marca),
          if (descripcion.isNotEmpty)
            _ResumenItem(icon: Icons.notes_rounded,      label: 'Descripción',    valor: descripcion, multilinea: true),
          _ResumenItem(
            icon: Icons.inventory_2_outlined,
            label: 'Stock',
            valor: stock == null
                ? 'Sin control de stock'
                : stock == 0
                    ? 'Agotado (0 unidades)'
                    : '$stock unidades disponibles',
          ),
          _ResumenItem(
            icon: Icons.delivery_dining_rounded,
            label: 'Domicilio',
            valor: aceptaDomicilio ? 'Sí, ofrece domicilio' : 'Solo recogida',
            valorColor: aceptaDomicilio ? AppColors.blue : null,
          ),
          if (metodosPago.isNotEmpty)
            _ResumenItem(
              icon: Icons.payments_outlined,
              label: 'Métodos de pago',
              valor: metodosPago.map(_labelMetodo).join(' · '),
            ),
          if (contacto.isNotEmpty)
            _ResumenItem(icon: Icons.phone_outlined, label: 'Contacto', valor: contacto),
        ],
      ),
    );
  }

  String _labelMetodo(String m) {
    const mapa = {
      'EFECTIVO':      'Efectivo',
      'NEQUI':         'Nequi',
      'DAVIPLATA':     'Daviplata',
      'TRANSFERENCIA': 'Transferencia',
      'BANCOLOMBIA':   'Bancolombia',
    };
    return mapa[m] ?? m;
  }
}

class _TarjetaPreview extends StatelessWidget {
  final String titulo;
  final String precio;
  final String categoria;
  final String marca;
  final String descripcion;
  final int? stock;
  final bool aceptaDomicilio;
  final List<String> metodosPago;

  const _TarjetaPreview({
    required this.titulo,
    required this.precio,
    required this.categoria,
    required this.marca,
    required this.descripcion,
    required this.stock,
    required this.aceptaDomicilio,
    required this.metodosPago,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge ACTIVA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Activa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ok,
                    )),
              ),
              const Spacer(),
              Text('Vista previa',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),

          // Título
          Text(
            titulo.isNotEmpty ? titulo : 'Sin título',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: titulo.isEmpty ? cs.onSurfaceVariant : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (marca.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(marca,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(descripcion,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),

          // Precio + categoría
          Row(
            children: [
              Text(precio,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(categoria,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (stock != null)
                _badgeStock(stock!),
              _badgeDomicilio(aceptaDomicilio),
              ...metodosPago.take(3).map(_badgeMetodo),
              if (metodosPago.length > 3)
                _badgeExtra(metodosPago.length - 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeStock(int s) {
    final Color bg;
    final Color fg;
    final String lbl;
    if (s <= 0) {
      bg = AppColors.dangerSoft; fg = AppColors.danger; lbl = 'Agotado';
    } else if (s == 1) {
      bg = AppColors.warningSoft; fg = AppColors.warning; lbl = 'Último';
    } else {
      bg = AppColors.bgGreen; fg = AppColors.ok; lbl = '$s uds.';
    }
    return _Chip(bg: bg, fg: fg, icon: Icons.inventory_2_outlined, label: lbl);
  }

  Widget _badgeDomicilio(bool acepta) {
    return _Chip(
      bg: acepta ? AppColors.bgBlue : AppColors.neutralSoft,
      fg: acepta ? AppColors.blue : AppColors.textLoLight,
      icon: Icons.delivery_dining_outlined,
      label: acepta ? 'Con domicilio' : 'Sin domicilio',
    );
  }

  Widget _badgeMetodo(String m) {
    const etiquetas = {
      'EFECTIVO':      'Efectivo',
      'NEQUI':         'Nequi',
      'DAVIPLATA':     'Daviplata',
      'TRANSFERENCIA': 'Transfer.',
      'BANCOLOMBIA':   'Bancolombia',
    };
    return Builder(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return _Chip(
          bg: cs.surfaceContainerHighest,
          fg: cs.onSurfaceVariant,
          icon: Icons.payments_outlined,
          label: etiquetas[m] ?? m,
        );
      },
    );
  }

  Widget _badgeExtra(int n) {
    return Builder(builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return _Chip(
        bg: cs.surfaceContainerHighest,
        fg: cs.onSurfaceVariant,
        icon: Icons.more_horiz,
        label: '+$n',
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String label;
  const _Chip({required this.bg, required this.fg, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final bool multilinea;
  final Color? valorColor;

  const _ResumenItem({
    required this.icon,
    required this.label,
    required this.valor,
    this.multilinea = false,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            multilinea ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                Text(valor,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: valorColor ?? cs.onSurface),
                    maxLines: multilinea ? 4 : 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets compartidos
// ─────────────────────────────────────────────────────────────────────────────

/// Scroll + padding estándar de cada paso con encabezado animado
class _PasoScroll extends StatelessWidget {
  final int pasoIndex;
  final Widget child;
  const _PasoScroll({required this.pasoIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final paso  = _kPasos[pasoIndex];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        // Encabezado del paso
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(paso.$1, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(paso.$2,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(paso.$3,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

/// Sublabel con icono para secciones dentro de un paso
class _SubLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  const _SubLabel({required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: cs.primary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                )),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 21),
          child: Text(sublabel,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}
