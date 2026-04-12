import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/models/insumo.dart';
import 'package:de_vacos/menu/builder/plato_builder.dart';
import 'package:de_vacos/menu/dominio/definicion/tier_definicion.dart';

void main() {
  Insumo makeInsumo(String nombre, {double precioExtra = 0.0}) => Insumo(
        id: 1,
        nombre: nombre,
        unidadMedida: 'u',
        cantidadActual: 10,
        precioExtra: precioExtra,
      );

  const tier1Prot1Acomp = TierDefinicion(
    nombre: 'Sencillo',
    precio: 15.0,
    maxProteinas: 1,
    maxAcompanantesGratis: 2,
  );

  const tier2Prot2Acomp = TierDefinicion(
    nombre: 'Doble',
    precio: 22.0,
    maxProteinas: 2,
    maxAcompanantesGratis: 2,
  );

  group('PlatoBuilder — proteínas', () {
    test('agrega proteína dentro del límite → Ok', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      final result = builder.agregarProteina(makeInsumo('Res'));
      expect(result.isOk, isTrue);
    });

    test('supera maxProteinas → Err', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      final result = builder.agregarProteina(makeInsumo('Pollo'));
      expect(result.isErr, isTrue);
      expect(result.error, contains('Sencillo'));
    });

    test('tier con 2 proteínas acepta 2 → Ok', () {
      final builder = PlatoBuilder(tier2Prot2Acomp);
      expect(builder.agregarProteina(makeInsumo('Res')).isOk, isTrue);
      expect(builder.agregarProteina(makeInsumo('Pollo')).isOk, isTrue);
    });

    test('build sin proteínas cuando tier requiere 1 → Err', () {
      final result = PlatoBuilder(tier1Prot1Acomp).build();
      expect(result.isErr, isTrue);
    });
  });

  group('PlatoBuilder — acompañantes gratis/pagos', () {
    test('primeros maxAcompanantesGratis son gratis', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      builder.agregarAcompanante(makeInsumo('Arroz', precioExtra: 2.0));
      builder.agregarAcompanante(makeInsumo('Ensalada', precioExtra: 1.5));
      final plato = builder.build().value;

      // Ambos dentro del límite gratis → precio 0
      expect(plato.acompanantes[0].getPrecio(), 0.0);
      expect(plato.acompanantes[1].getPrecio(), 0.0);
    });

    test('acompañante que supera límite gratis cobra precioExtra', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      builder.agregarAcompanante(makeInsumo('Arroz', precioExtra: 2.0));
      builder.agregarAcompanante(makeInsumo('Ensalada', precioExtra: 1.5));
      builder.agregarAcompanante(makeInsumo('Maduro', precioExtra: 1.0)); // tercer = pago
      final plato = builder.build().value;

      expect(plato.acompanantes[2].getPrecio(), 1.0);
    });
  });

  group('PlatoBuilder — extras', () {
    test('extra siempre cobra precioExtra', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      builder.agregarExtra(makeInsumo('Queso', precioExtra: 3.0));
      final plato = builder.build().value;

      expect(plato.extras[0].getPrecio(), 3.0);
    });
  });

  group('PlatoBuilder — precio total', () {
    test('precio base del tier sin extras', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      final plato = builder.build().value;

      expect(plato.getPrecio(), 15.0);
    });

    test('precio base + acompañante extra + extra', () {
      final builder = PlatoBuilder(tier1Prot1Acomp);
      builder.agregarProteina(makeInsumo('Res'));
      builder.agregarAcompanante(makeInsumo('Arroz', precioExtra: 2.0)); // gratis
      builder.agregarAcompanante(makeInsumo('Ensalada', precioExtra: 1.5)); // gratis
      builder.agregarAcompanante(makeInsumo('Maduro', precioExtra: 1.0)); // pago
      builder.agregarExtra(makeInsumo('Queso', precioExtra: 3.0));
      final plato = builder.build().value;

      // 15 (tier) + 1.0 (acomp pago) + 3.0 (extra)
      expect(plato.getPrecio(), 19.0);
    });
  });
}
