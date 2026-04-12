import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/menu/dominio/insumo/insumo_menu.dart';
import 'package:de_vacos/menu/dominio/insumo/i_insumo_menu_repository.dart';
import 'package:de_vacos/menu/servicios/stock_validator.dart';

/// Stub simple — no usa DB.
class _FakeRepo implements IInsumoMenuRepository {
  final Map<int, InsumoMenu> _data;

  _FakeRepo(this._data);

  @override
  Future<InsumoMenu?> findById(int id) async => _data[id];

  @override
  Future<List<InsumoMenu>> findAll() async => _data.values.toList();

  @override
  Future<void> save(InsumoMenu insumo) async => _data[insumo.id] = insumo;
}

Insumo _insumo(int id, String nombre) => Insumo(
      id: id,
      nombre: nombre,
      unidadMedida: 'u',
      cantidadActual: 5,
    );

InsumoMenu _stock(int id, String nombre, double porciones) =>
    InsumoMenu(id: id, nombre: nombre, porcionesDisponibles: porciones);

void main() {
  group('StockValidator.validar', () {
    test('stock suficiente → Ok(true)', () async {
      final repo = _FakeRepo({
        1: _stock(1, 'Res', 3.0),
      });
      final validator = StockValidator(repo);
      final result = await validator.validar([_insumo(1, 'Res')]);
      expect(result.isOk, isTrue);
      expect(result.value, isTrue);
    });

    test('proteína sin stock → Err con nombre', () async {
      final repo = _FakeRepo({
        1: _stock(1, 'Pollo', 0.0),
      });
      final validator = StockValidator(repo);
      final result = await validator.validar([_insumo(1, 'Pollo')]);
      expect(result.isErr, isTrue);
      expect(result.error, contains('Pollo'));
    });

    test('proteína no encontrada en repo → Err', () async {
      final repo = _FakeRepo({});
      final validator = StockValidator(repo);
      final result = await validator.validar([_insumo(99, 'Inexistente')]);
      expect(result.isErr, isTrue);
      expect(result.error, contains('Inexistente'));
    });

    test('lista vacía → Ok(true)', () async {
      final repo = _FakeRepo({});
      final validator = StockValidator(repo);
      final result = await validator.validar([]);
      expect(result.isOk, isTrue);
    });

    test('múltiples proteínas — falla en la segunda', () async {
      final repo = _FakeRepo({
        1: _stock(1, 'Res', 2.0),
        2: _stock(2, 'Pollo', 0.0),
      });
      final validator = StockValidator(repo);
      final result = await validator.validar([
        _insumo(1, 'Res'),
        _insumo(2, 'Pollo'),
      ]);
      expect(result.isErr, isTrue);
      expect(result.error, contains('Pollo'));
    });
  });
}
