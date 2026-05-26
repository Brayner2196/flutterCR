import 'package:flutter/material.dart';

// ─── Catálogo de timezones ────────────────────────────────────────────────────

class _TzEntry {
  final String pais;
  final String ciudad;
  final String iana;
  const _TzEntry(this.pais, this.ciudad, this.iana);

  String get etiqueta => '$pais — $ciudad';
}

const _timezones = [
  // ── Latinoamérica ──────────────────────────────────────────────────────────
  _TzEntry('Colombia',              'Bogotá',            'America/Bogota'),
  _TzEntry('Argentina',             'Buenos Aires',      'America/Argentina/Buenos_Aires'),
  _TzEntry('Perú',                  'Lima',              'America/Lima'),
  _TzEntry('Chile',                 'Santiago',          'America/Santiago'),
  _TzEntry('Venezuela',             'Caracas',           'America/Caracas'),
  _TzEntry('Bolivia',               'La Paz',            'America/La_Paz'),
  _TzEntry('Paraguay',              'Asunción',          'America/Asuncion'),
  _TzEntry('Uruguay',               'Montevideo',        'America/Montevideo'),
  _TzEntry('Ecuador',               'Guayaquil',         'America/Guayaquil'),
  _TzEntry('Brasil',                'São Paulo',         'America/Sao_Paulo'),
  _TzEntry('Brasil',                'Manaos',            'America/Manaus'),
  _TzEntry('México',                'Ciudad de México',  'America/Mexico_City'),
  _TzEntry('México',                'Cancún',            'America/Cancun'),
  _TzEntry('Cuba',                  'La Habana',         'America/Havana'),
  _TzEntry('Panamá',                'Ciudad de Panamá',  'America/Panama'),
  _TzEntry('Costa Rica',            'San José',          'America/Costa_Rica'),
  _TzEntry('Honduras',              'Tegucigalpa',       'America/Tegucigalpa'),
  _TzEntry('Nicaragua',             'Managua',           'America/Managua'),
  _TzEntry('El Salvador',           'San Salvador',      'America/El_Salvador'),
  _TzEntry('Guatemala',             'Guatemala',         'America/Guatemala'),
  _TzEntry('Belice',                'Belice',            'America/Belize'),
  _TzEntry('Rep. Dominicana',       'Santo Domingo',     'America/Santo_Domingo'),
  _TzEntry('Haití',                 'Puerto Príncipe',   'America/Port-au-Prince'),
  _TzEntry('Jamaica',               'Kingston',          'America/Jamaica'),
  _TzEntry('Puerto Rico',           'San Juan',          'America/Puerto_Rico'),
  _TzEntry('Barbados',              'Bridgetown',        'America/Barbados'),
  _TzEntry('Trinidad y Tobago',     'Puerto España',     'America/Trinidad'),
  _TzEntry('Guyana',                'Georgetown',        'America/Guyana'),
  _TzEntry('Surinam',               'Paramaribo',        'America/Paramaribo'),
  _TzEntry('Guayana Francesa',      'Cayena',            'America/Cayenne'),
  // ── Norteamérica ──────────────────────────────────────────────────────────
  _TzEntry('Estados Unidos (Este)', 'Nueva York',        'America/New_York'),
  _TzEntry('Estados Unidos (Centro)','Chicago',          'America/Chicago'),
  _TzEntry('Estados Unidos (Montaña)','Denver',          'America/Denver'),
  _TzEntry('Estados Unidos (Pacífico)','Los Ángeles',    'America/Los_Angeles'),
  _TzEntry('Canadá (Este)',          'Toronto',          'America/Toronto'),
  _TzEntry('Canadá (Pacífico)',      'Vancouver',        'America/Vancouver'),
  // ── Europa ────────────────────────────────────────────────────────────────
  _TzEntry('España',                'Madrid',            'Europe/Madrid'),
  _TzEntry('España (Canarias)',      'Las Palmas',        'Atlantic/Canary'),
  _TzEntry('Portugal',              'Lisboa',            'Europe/Lisbon'),
  _TzEntry('Reino Unido',           'Londres',           'Europe/London'),
  _TzEntry('Francia',               'París',             'Europe/Paris'),
  _TzEntry('Alemania',              'Berlín',            'Europe/Berlin'),
  _TzEntry('Italia',                'Roma',              'Europe/Rome'),
  _TzEntry('Países Bajos',          'Ámsterdam',         'Europe/Amsterdam'),
  _TzEntry('Bélgica',               'Bruselas',          'Europe/Brussels'),
  _TzEntry('Suiza',                 'Zúrich',            'Europe/Zurich'),
  _TzEntry('Austria',               'Viena',             'Europe/Vienna'),
  _TzEntry('Polonia',               'Varsovia',          'Europe/Warsaw'),
  _TzEntry('Rep. Checa',            'Praga',             'Europe/Prague'),
  _TzEntry('Suecia',                'Estocolmo',         'Europe/Stockholm'),
  _TzEntry('Noruega',               'Oslo',              'Europe/Oslo'),
  _TzEntry('Dinamarca',             'Copenhague',        'Europe/Copenhagen'),
  _TzEntry('Finlandia',             'Helsinki',          'Europe/Helsinki'),
  _TzEntry('Grecia',                'Atenas',            'Europe/Athens'),
  _TzEntry('Rumania',               'Bucarest',          'Europe/Bucharest'),
  _TzEntry('Hungría',               'Budapest',          'Europe/Budapest'),
  _TzEntry('Bulgaria',              'Sofía',             'Europe/Sofia'),
  _TzEntry('Turquía',               'Estambul',          'Europe/Istanbul'),
  _TzEntry('Ucrania',               'Kiev',              'Europe/Kyiv'),
  _TzEntry('Rusia',                 'Moscú',             'Europe/Moscow'),
  _TzEntry('Rusia (Ekaterimburgo)', 'Ekaterimburgo',     'Asia/Yekaterinburg'),
  // ── Oriente Medio ─────────────────────────────────────────────────────────
  _TzEntry('Emiratos Árabes',       'Dubái',             'Asia/Dubai'),
  _TzEntry('Arabia Saudita',        'Riad',              'Asia/Riyadh'),
  _TzEntry('Irak',                  'Bagdad',            'Asia/Baghdad'),
  _TzEntry('Líbano',                'Beirut',            'Asia/Beirut'),
  _TzEntry('Israel',                'Jerusalén',         'Asia/Jerusalem'),
  // ── Asia ──────────────────────────────────────────────────────────────────
  _TzEntry('Pakistán',              'Karachi',           'Asia/Karachi'),
  _TzEntry('India',                 'Bombay / Delhi',    'Asia/Kolkata'),
  _TzEntry('Bangladés',             'Daca',              'Asia/Dhaka'),
  _TzEntry('Tailandia',             'Bangkok',           'Asia/Bangkok'),
  _TzEntry('Indonesia',             'Yakarta',           'Asia/Jakarta'),
  _TzEntry('Singapur',              'Singapur',          'Asia/Singapore'),
  _TzEntry('Malasia',               'Kuala Lumpur',      'Asia/Kuala_Lumpur'),
  _TzEntry('Filipinas',             'Manila',            'Asia/Manila'),
  _TzEntry('China',                 'Pekín / Shanghái',  'Asia/Shanghai'),
  _TzEntry('Hong Kong',             'Hong Kong',         'Asia/Hong_Kong'),
  _TzEntry('Corea del Sur',         'Seúl',              'Asia/Seoul'),
  _TzEntry('Japón',                 'Tokio',             'Asia/Tokyo'),
  // ── Oceanía ───────────────────────────────────────────────────────────────
  _TzEntry('Australia (Este)',       'Sídney',            'Australia/Sydney'),
  _TzEntry('Australia (Centro)',     'Adelaida',          'Australia/Adelaide'),
  _TzEntry('Australia (Oeste)',      'Perth',             'Australia/Perth'),
  _TzEntry('Nueva Zelanda',          'Auckland',          'Pacific/Auckland'),
  // ── África ────────────────────────────────────────────────────────────────
  _TzEntry('Egipto',                'El Cairo',          'Africa/Cairo'),
  _TzEntry('Nigeria',               'Lagos',             'Africa/Lagos'),
  _TzEntry('Kenia',                 'Nairobi',           'Africa/Nairobi'),
  _TzEntry('Sudáfrica',             'Johannesburgo',     'Africa/Johannesburg'),
  _TzEntry('Marruecos',             'Casablanca',        'Africa/Casablanca'),
  _TzEntry('Ghana',                 'Acra',              'Africa/Accra'),
];

// ─── Widget picker ────────────────────────────────────────────────────────────

/// Campo tocable que abre un bottom-sheet con búsqueda por nombre de país.
class TimezonePickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;

  const TimezonePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Buscar la entrada correspondiente al valor actual
    final entry = _timezones.firstWhere(
      (e) => e.iana == value,
      orElse: () => _TzEntry('Colombia', 'Bogotá', 'America/Bogota'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Zona horaria usada para calcular vencimientos y moras.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirPicker(context),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.public, color: cs.primary),
              suffixIcon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.pais,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  entry.iana,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _abrirPicker(BuildContext context) async {
    final seleccionado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TimezonePickerSheet(valorActual: value),
    );
    if (seleccionado != null) onChanged(seleccionado);
  }
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _TimezonePickerSheet extends StatefulWidget {
  final String valorActual;
  const _TimezonePickerSheet({required this.valorActual});

  @override
  State<_TimezonePickerSheet> createState() => _TimezonePickerSheetState();
}

class _TimezonePickerSheetState extends State<_TimezonePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_TzEntry> _filtrados = List.of(_timezones);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filtrar);
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? List.of(_timezones)
          : _timezones
              .where((e) =>
                  e.pais.toLowerCase().contains(q) ||
                  e.ciudad.toLowerCase().contains(q) ||
                  e.iana.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Título ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(Icons.public, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Zona horaria',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Buscador ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por país o ciudad...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filtrar();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Lista ─────────────────────────────────────────────────────────
          Expanded(
            child: _filtrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 40, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Sin resultados',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) {
                      final e = _filtrados[i];
                      final seleccionado = e.iana == widget.valorActual;
                      return ListTile(
                        selected: seleccionado,
                        selectedTileColor: cs.primary.withValues(alpha: 0.08),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? cs.primary.withValues(alpha: 0.12)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.public,
                            size: 18,
                            color: seleccionado
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          e.pais,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: seleccionado ? cs.primary : cs.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${e.ciudad}  ·  ${e.iana}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: seleccionado
                            ? Icon(Icons.check_circle_rounded,
                                color: cs.primary, size: 20)
                            : null,
                        onTap: () => Navigator.pop(context, e.iana),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
