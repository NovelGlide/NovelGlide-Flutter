import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';

void main() {
  group('CollectionData', () {
    // Test fixtures
    final DateTime now = DateTime.now();
    final DateTime later = now.add(const Duration(hours: 1));

    final CollectionData collection = CollectionData(
      id: 'col-1',
      name: 'Test Collection',
      bookIds: const <String>['book-1', 'book-2', 'book-3'],
      description: 'A test collection',
      createdAt: now,
      updatedAt: now,
      color: '#FF5722',
    );

    group('Immutability & Equality', () {
      test('entities with same values are equal', () {
        final CollectionData collection1 = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );
        final CollectionData collection2 = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        expect(collection1, equals(collection2));
      });

      test('entities with different values are not equal', () {
        final CollectionData collection1 = CollectionData(
          id: 'col-1',
          name: 'Test1',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );
        final CollectionData collection2 = CollectionData(
          id: 'col-2',
          name: 'Test2',
          bookIds: const <String>['book-2'],
          createdAt: now,
          updatedAt: now,
        );

        expect(collection1, isNot(equals(collection2)));
      });

      test('copyWith creates a new instance with modified fields', () {
        final CollectionData modified = collection.copyWith(
          name: 'Updated Collection',
        );

        expect(modified.id, equals(collection.id));
        expect(modified.name, equals('Updated Collection'));
        expect(modified.bookIds, equals(collection.bookIds));
        expect(modified, isNot(equals(collection)));
      });

      test('copyWith does not modify original', () {
        final CollectionData original = CollectionData(
          id: 'col-1',
          name: 'Original',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        final CollectionData modified = original.copyWith(
          name: 'Modified',
        );

        expect(original.name, equals('Original'));
        expect(modified.name, equals('Modified'));
      });

      test('copyWith can modify bookIds', () {
        final CollectionData modified = collection.copyWith(
          bookIds: const <String>['book-1', 'book-2', 'book-3', 'book-4'],
        );

        expect(modified.bookIds, hasLength(4));
        expect(collection.bookIds, hasLength(3));
      });

      test('copyWith can modify color', () {
        final CollectionData modified = collection.copyWith(
          color: '#00FF00',
        );

        expect(modified.color, equals('#00FF00'));
        expect(collection.color, equals('#FF5722'));
      });

      test('copyWith can modify description', () {
        final CollectionData modified = collection.copyWith(
          description: 'Updated description',
        );

        expect(modified.description, equals('Updated description'));
      });

      test('copyWith can modify updatedAt', () {
        final CollectionData modified = collection.copyWith(
          updatedAt: later,
        );

        expect(modified.updatedAt, equals(later));
        expect(collection.updatedAt, equals(now));
      });

      test('hashCode is equal for equal entities', () {
        final CollectionData collection1 = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );
        final CollectionData collection2 = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        expect(collection1.hashCode, equals(collection2.hashCode));
      });

      test('hashCode differs for unequal entities', () {
        final CollectionData collection1 = CollectionData(
          id: 'col-1',
          name: 'Test1',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );
        final CollectionData collection2 = CollectionData(
          id: 'col-2',
          name: 'Test2',
          bookIds: const <String>['book-2'],
          createdAt: now,
          updatedAt: now,
        );

        expect(
          collection1.hashCode,
          isNot(equals(collection2.hashCode)),
        );
      });
    });

    group('JSON Serialization', () {
      test('toJson produces correct format with bookIds', () {
        final Map<String, dynamic> json = collection.toJson();

        expect(json['id'], equals('col-1'));
        expect(json['name'], equals('Test Collection'));
        expect(
          json['bookIds'],
          equals(<String>['book-1', 'book-2', 'book-3']),
        );
        expect(json['description'], equals('A test collection'));
        expect(json['color'], equals('#FF5722'));
        expect(json['createdAt'], isNotEmpty);
        expect(json['updatedAt'], isNotEmpty);
      });

      test('fromJson creates entity from valid JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'col-1',
          'name': 'Test Collection',
          'bookIds': <String>['book-1', 'book-2'],
          'description': 'A test collection',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'color': '#FF5722',
        };

        final CollectionData entity = CollectionData.fromJson(json);

        expect(entity.id, equals('col-1'));
        expect(entity.name, equals('Test Collection'));
        expect(entity.bookIds, equals(<String>['book-1', 'book-2']));
        expect(entity.description, equals('A test collection'));
        expect(entity.color, equals('#FF5722'));
      });

      test('round-trip serialization preserves all fields', () {
        final Map<String, dynamic> json = collection.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized, equals(collection));
      });

      test('fromJson handles empty bookIds list', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'col-1',
          'name': 'Empty Collection',
          'bookIds': <String>[],
          'description': '',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'color': '#808080',
        };

        final CollectionData entity = CollectionData.fromJson(json);

        expect(entity.bookIds, isEmpty);
        expect(entity.bookIds, equals(<String>[]));
      });

      test('fromJson uses default values for optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 'col-1',
          'name': 'Test',
          'bookIds': <String>['book-1'],
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        final CollectionData entity = CollectionData.fromJson(json);

        expect(entity.description, equals(''));
        expect(entity.color, equals('#808080'));
      });
    });

    group('Edge Cases', () {
      test('entity with special characters in name', () {
        final CollectionData special = CollectionData(
          id: 'col-special',
          name: 'Ѐ™¡Ñvèñ ©ô£&Ōëç†ïøñ',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = special.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.name, equals(special.name));
        expect(deserialized, equals(special));
      });

      test('entity with special characters in description', () {
        final CollectionData special = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          description: 'Line1\nLine2\tTabbed\r\nWindows',
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = special.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.description, equals(special.description));
      });

      test('entity with many bookIds (50+ books)', () {
        final List<String> manyBookIds = <String>[
          for (int i = 0; i < 100; i++) 'book-$i'
        ];

        final CollectionData large = CollectionData(
          id: 'col-large',
          name: 'Large Collection',
          bookIds: manyBookIds,
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = large.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.bookIds, hasLength(100));
        expect(deserialized, equals(large));
      });

      test('entity with very long name', () {
        final String longName = 'A' * 500;
        final CollectionData longNamed = CollectionData(
          id: 'col-1',
          name: longName,
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = longNamed.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.name, equals(longName));
      });

      test('bookIds with UUID format', () {
        final CollectionData withUuids = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>[
            '550e8400-e29b-41d4-a716-446655440000',
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
          ],
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = withUuids.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.bookIds, equals(withUuids.bookIds));
      });

      test('color field preserves hex format', () {
        final List<String> colors = <String>[
          '#000000',
          '#FFFFFF',
          '#FF5722',
          '#4CAF50',
          '#2196F3',
        ];

        for (final String color in colors) {
          final CollectionData colored = CollectionData(
            id: 'col-1',
            name: 'Test',
            bookIds: const <String>['book-1'],
            createdAt: now,
            updatedAt: now,
            color: color,
          );

          final Map<String, dynamic> json = colored.toJson();
          final CollectionData deserialized =
              CollectionData.fromJson(json);

          expect(deserialized.color, equals(color));
        }
      });
    });

    group('Empty Collection', () {
      test('empty collection with no books', () {
        final CollectionData empty = CollectionData(
          id: 'col-empty',
          name: 'Empty Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        expect(empty.bookIds, isEmpty);
        expect(empty.bookIds, equals(<String>[]));
      });

      test('empty collection serialization round-trip', () {
        final CollectionData empty = CollectionData(
          id: 'col-empty',
          name: 'Empty',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = empty.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.bookIds, isEmpty);
        expect(deserialized, equals(empty));
      });
    });

    group('BookId Validation', () {
      test('accepts valid BookId format', () {
        final CollectionData validated = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['valid-book-id-123'],
          createdAt: now,
          updatedAt: now,
        );

        expect(validated.bookIds[0], equals('valid-book-id-123'));
      });

      test('maintains bookId order in list', () {
        final CollectionData ordered = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>[
            'book-z',
            'book-a',
            'book-m',
          ],
          createdAt: now,
          updatedAt: now,
        );

        expect(ordered.bookIds[0], equals('book-z'));
        expect(ordered.bookIds[1], equals('book-a'));
        expect(ordered.bookIds[2], equals('book-m'));

        final Map<String, dynamic> json = ordered.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.bookIds[0], equals('book-z'));
        expect(deserialized.bookIds[1], equals('book-a'));
        expect(deserialized.bookIds[2], equals('book-m'));
      });

      test('allows duplicate bookIds (order significant)', () {
        final CollectionData withDuplicates = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1', 'book-1', 'book-2'],
          createdAt: now,
          updatedAt: now,
        );

        expect(withDuplicates.bookIds, hasLength(3));
        expect(
          withDuplicates.bookIds,
          equals(<String>['book-1', 'book-1', 'book-2']),
        );
      });
    });
  });
}
