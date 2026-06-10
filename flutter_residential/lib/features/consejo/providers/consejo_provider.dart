import '../../../core/providers/base_provider.dart';
import '../../pqr/models/pqr_model.dart';
import '../models/miembro_consejo_model.dart';
import '../services/consejo_service.dart';

class ConsejoProvider extends BaseProvider {
  List<MiembroConsejoModel> _directorio = [];
  List<PqrModel> _pqrs = [];
  String? _filtroPqr;

  // ─── Getters ──────────────────────────────────────────────────

  List<MiembroConsejoModel> get directorio => _directorio;
  List<PqrModel> get pqrs => _pqrs;
  String? get filtroPqr => _filtroPqr;

  int get pqrsPendientes =>
      _pqrs.where((p) => p.esPendiente).length;

  // ─── Cargar ───────────────────────────────────────────────────

  Future<void> cargarDirectorio() async {
    _directorio = await ejecutar(
      () => ConsejoService.listarDirectorio(),
    ) ?? [];
  }

  Future<void> cargarPqrs({String? estado}) async {
    _filtroPqr = estado;
    _pqrs = await ejecutar(
      () => ConsejoService.listarPqrs(estado: estado),
    ) ?? [];
  }
}
