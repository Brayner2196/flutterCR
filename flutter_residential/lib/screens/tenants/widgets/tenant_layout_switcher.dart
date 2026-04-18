import 'package:flutter/material.dart';
import 'package:flutter_residential/core/enums/enum_mod_layouts_screen_tenants.dart';


class TenantLayoutSwitcher extends StatelessWidget {

  final ModosLayouts mode;
  final ValueChanged<ModosLayouts> onChanged;
  const TenantLayoutSwitcher({ required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;
    Widget iconBtn(IconData icon, ModosLayouts m) {
      final selected = mode == m;
      return GestureDetector(
        onTap: () => onChanged(m),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 17,
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          iconBtn(Icons.view_agenda_outlined, ModosLayouts.list),
          iconBtn(Icons.grid_view_outlined, ModosLayouts.grid),
          iconBtn(Icons.table_rows_outlined, ModosLayouts.table),
        ],
      ),
    );

  }
}