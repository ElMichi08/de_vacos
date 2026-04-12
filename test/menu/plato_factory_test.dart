import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/models/modalidad.dart';
import 'package:de_vacos/menu/factory/plato_factory.dart';
import 'package:de_vacos/menu/dominio/definicion/menu_item_definicion.dart';
import 'package:de_vacos/menu/dominio/definicion/tier_definicion.dart';

void main() {
  Insumo makeInsumo(String nombre, {int id = 1, double precioExtra = 0.0}) =>
      Insumo(
        id: id,
        nombre: nombre,
        unidadMedida: 'u',
        cantidadActual: 10,
        precioExtra: precioExtra,
      );

  final defSencillo = MenuItemDefinicion(
    id: 1,
    nombre: 'Plato de la Casa',
    tiers: const [
      TierDefinicion(
        nombre: 'Sencillo',
        precio: 15.0,
        maxProteinas: 1,
        maxAcompanantesGratis: 2,
      ),
      TierDefinicion(
        nombre: 'Doble',
        precio: 22.0,
        maxProteinas: 2,
        maxAcompanantesGratis: 2,
      ),
    ],
    proteinaIds: const [1, 2],
    acompananteIds: const [3, 4],
  );

  group('PlatoFactory.crear — tier', () {
    test('tier válido crea el plato correctamente', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [makeInsumo('Res')],
      );
      final result = PlatoFactory.crear(defSencillo, seleccion);
      expect(result.isOk, isTrue);
      expect(result.value.tier.nombre, 'Sencillo');
      expect(result.value.tier.precio, 15.0);
    });

    test('tier inválido → Err con mensaje', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Triple',
        proteinas: [makeInsumo('Res')],
      );
      final result = PlatoFactory.crear(defSencillo, seleccion);
      expect(result.isErr, isTrue);
      expect(result.error, contains('Triple'));
    });

    test('comparación de tier es case-insensitive', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'sencillo',
        proteinas: [makeInsumo('Res')],
      );
      expect(PlatoFactory.crear(defSencillo, seleccion).isOk, isTrue);
    });
  });

  group('PlatoFactory.crear — proteínas', () {
    test('sin proteínas cuando tier requiere 1 → Err', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [],
      );
      final result = PlatoFactory.crear(defSencillo, seleccion);
      expect(result.isErr, isTrue);
    });

    test('superar maxProteinas → Err', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [makeInsumo('Res', id: 1), makeInsumo('Pollo', id: 2)],
      );
      final result = PlatoFactory.crear(defSencillo, seleccion);
      expect(result.isErr, isTrue);
    });

    test('tier Doble acepta 2 proteínas', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Doble',
        proteinas: [makeInsumo('Res', id: 1), makeInsumo('Pollo', id: 2)],
      );
      final result = PlatoFactory.crear(defSencillo, seleccion);
      expect(result.isOk, isTrue);
      expect(result.value.proteinas.length, 2);
    });
  });

  group('PlatoFactory.crear — acompañantes y extras', () {
    test('acompañantes y extras se reflejan en el plato', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [makeInsumo('Res')],
        acompanantes: [makeInsumo('Arroz', id: 3), makeInsumo('Ensalada', id: 4)],
        extras: [makeInsumo('Queso', id: 5, precioExtra: 2.0)],
      );
      final plato = PlatoFactory.crear(defSencillo, seleccion).value;
      expect(plato.acompanantes.length, 2);
      expect(plato.extras.length, 1);
    });
  });

  group('PlatoFactory.crear — modalidad', () {
    test('SeleccionPlato puede llevar modalidad nula', () {
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [makeInsumo('Res')],
        modalidad: null,
      );
      expect(PlatoFactory.crear(defSencillo, seleccion).isOk, isTrue);
    });

    test('SeleccionPlato con modalidad asignada', () {
      const modal = Modalidad(id: 1, nombre: 'Feria', modificador: 2.0);
      final seleccion = SeleccionPlato(
        tierNombre: 'Sencillo',
        proteinas: [makeInsumo('Res')],
        modalidad: modal,
      );
      final sel = seleccion;
      expect(sel.modalidad?.nombre, 'Feria');
      expect(PlatoFactory.crear(defSencillo, seleccion).isOk, isTrue);
    });
  });
}
