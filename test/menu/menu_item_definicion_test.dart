import 'package:flutter_test/flutter_test.dart';
import 'package:de_vacos/menu/dominio/definicion/menu_item_definicion.dart';
import 'package:de_vacos/menu/dominio/definicion/tier_definicion.dart';

void main() {
  const tiers = [
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
  ];

  final completo = MenuItemDefinicion(
    id: 42,
    nombre: 'Plato de la Casa',
    tiers: tiers,
    proteinaIds: const [1, 2, 3],
    acompananteIds: const [4, 5],
    extraIds: const [6],
    modalidadIds: const [7, 8],
    cancelado: false,
  );

  group('MenuItemDefinicion.toMap / fromMap — round trip', () {
    test('toMap produce claves correctas', () {
      final map = completo.toMap();
      expect(map['id'], 42);
      expect(map['nombre'], 'Plato de la Casa');
      expect(map.containsKey('tiers'), isTrue);
      expect(map.containsKey('proteinas'), isTrue);
      expect(map.containsKey('acompanantes'), isTrue);
      expect(map.containsKey('extras'), isTrue);
      expect(map.containsKey('modificadores'), isTrue);
      expect(map['cancelado'], 0);
    });

    test('fromMap restaura ids correctamente', () {
      final map = completo.toMap();
      final restaurado = MenuItemDefinicion.fromMap(map);

      expect(restaurado.id, 42);
      expect(restaurado.nombre, 'Plato de la Casa');
      expect(restaurado.proteinaIds, [1, 2, 3]);
      expect(restaurado.acompananteIds, [4, 5]);
      expect(restaurado.extraIds, [6]);
      expect(restaurado.modalidadIds, [7, 8]);
      expect(restaurado.cancelado, isFalse);
    });

    test('fromMap restaura tiers con sus campos', () {
      final restaurado =
          MenuItemDefinicion.fromMap(completo.toMap());
      expect(restaurado.tiers.length, 2);
      expect(restaurado.tiers[0].nombre, 'Sencillo');
      expect(restaurado.tiers[0].precio, 15.0);
      expect(restaurado.tiers[0].maxProteinas, 1);
      expect(restaurado.tiers[0].maxAcompanantesGratis, 2);
      expect(restaurado.tiers[1].nombre, 'Doble');
    });

    test('cancelado=true se serializa y restaura', () {
      final cancelado = completo.copyWith(cancelado: true);
      final map = cancelado.toMap();
      expect(map['cancelado'], 1);
      expect(MenuItemDefinicion.fromMap(map).cancelado, isTrue);
    });

    test('listas vacías sobreviven round trip', () {
      final vacio = MenuItemDefinicion(
        id: 1,
        nombre: 'Vacío',
        tiers: const [
          TierDefinicion(
            nombre: 'Base',
            precio: 10.0,
            maxProteinas: 1,
            maxAcompanantesGratis: 1,
          ),
        ],
      );
      final restaurado = MenuItemDefinicion.fromMap(vacio.toMap());
      expect(restaurado.proteinaIds, isEmpty);
      expect(restaurado.acompananteIds, isEmpty);
      expect(restaurado.extraIds, isEmpty);
      expect(restaurado.modalidadIds, isEmpty);
    });
  });

  group('MenuItemDefinicion.copyWith', () {
    test('copyWith nombre actualiza solo el nombre', () {
      final copia = completo.copyWith(nombre: 'Nuevo Nombre');
      expect(copia.nombre, 'Nuevo Nombre');
      expect(copia.id, completo.id);
      expect(copia.proteinaIds, completo.proteinaIds);
    });

    test('copyWith proteinaIds reemplaza la lista', () {
      final copia = completo.copyWith(proteinaIds: [9, 10]);
      expect(copia.proteinaIds, [9, 10]);
      expect(copia.acompananteIds, completo.acompananteIds);
    });
  });
}
