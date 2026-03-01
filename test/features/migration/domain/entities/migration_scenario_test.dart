import 'package:flutter_test/flutter_test.dart';
import 'package:migration_implementation/features/migration/domain/entities/migration_scenario.dart';

void main() {
  group('MigrationScenario', () {
    group('Enum Values', () {
      test('localAndCloud exists', () {
        expect(MigrationScenario.localAndCloud, isNotNull);
      });

      test('localOnly exists', () {
        expect(MigrationScenario.localOnly, isNotNull);
      });

      test('cloudOnly exists', () {
        expect(MigrationScenario.cloudOnly, isNotNull);
      });

      test('none exists', () {
        expect(MigrationScenario.none, isNotNull);
      });

      test('all values are accessible', () {
        expect(MigrationScenario.values.length, 4);
        expect(
          MigrationScenario.values,
          containsAll([
            MigrationScenario.localAndCloud,
            MigrationScenario.localOnly,
            MigrationScenario.cloudOnly,
            MigrationScenario.none,
          ]),
        );
      });
    });

    group('Enum Behavior in Switch', () {
      test('localAndCloud matched in switch statement', () {
        final scenario = MigrationScenario.localAndCloud;
        String result;

        switch (scenario) {
          case MigrationScenario.localAndCloud:
            result = 'merged';
          case MigrationScenario.localOnly:
            result = 'local';
          case MigrationScenario.cloudOnly:
            result = 'cloud';
          case MigrationScenario.none:
            result = 'none';
        }

        expect(result, 'merged');
      });

      test('localOnly matched in switch statement', () {
        final scenario = MigrationScenario.localOnly;
        String result;

        switch (scenario) {
          case MigrationScenario.localAndCloud:
            result = 'merged';
          case MigrationScenario.localOnly:
            result = 'local';
          case MigrationScenario.cloudOnly:
            result = 'cloud';
          case MigrationScenario.none:
            result = 'none';
        }

        expect(result, 'local');
      });

      test('cloudOnly matched in switch statement', () {
        final scenario = MigrationScenario.cloudOnly;
        String result;

        switch (scenario) {
          case MigrationScenario.localAndCloud:
            result = 'merged';
          case MigrationScenario.localOnly:
            result = 'local';
          case MigrationScenario.cloudOnly:
            result = 'cloud';
          case MigrationScenario.none:
            result = 'none';
        }

        expect(result, 'cloud');
      });

      test('none matched in switch statement', () {
        final scenario = MigrationScenario.none;
        String result;

        switch (scenario) {
          case MigrationScenario.localAndCloud:
            result = 'merged';
          case MigrationScenario.localOnly:
            result = 'local';
          case MigrationScenario.cloudOnly:
            result = 'cloud';
          case MigrationScenario.none:
            result = 'none';
        }

        expect(result, 'none');
      });
    });

    group('Equality and Comparison', () {
      test('same scenario values are equal', () {
        expect(
          MigrationScenario.localAndCloud,
          equals(MigrationScenario.localAndCloud),
        );
      });

      test('different scenario values are not equal', () {
        expect(
          MigrationScenario.localAndCloud,
          isNot(equals(MigrationScenario.localOnly)),
        );
      });

      test('scenarios can be stored in collections', () {
        final scenarios = {
          MigrationScenario.localAndCloud,
          MigrationScenario.localOnly,
          MigrationScenario.cloudOnly,
        };

        expect(scenarios.length, 3);
        expect(scenarios.contains(MigrationScenario.localAndCloud), true);
        expect(scenarios.contains(MigrationScenario.none), false);
      });
    });

    group('String Representation', () {
      test('toString() returns expected format', () {
        expect(
          MigrationScenario.localAndCloud.toString(),
          'MigrationScenario.localAndCloud',
        );
        expect(
          MigrationScenario.localOnly.toString(),
          'MigrationScenario.localOnly',
        );
        expect(
          MigrationScenario.cloudOnly.toString(),
          'MigrationScenario.cloudOnly',
        );
        expect(
          MigrationScenario.none.toString(),
          'MigrationScenario.none',
        );
      });
    });
  });
}
