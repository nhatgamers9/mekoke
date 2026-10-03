import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/data/database.dart';
import 'package:steady/data/prefs_repository.dart';
import 'package:steady/features/timer/interval_config.dart';

void main() {
  late AppDatabase db;
  late PrefsRepository prefs;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    prefs = PrefsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> rowCount() async => (await db.select(db.prefs).get()).length;

  group('read and write', () {
    test('a name that was never written reads as null', () async {
      expect(await prefs.read('missing'), isNull);
    });

    test('what was written can be read back', () async {
      await prefs.write('a', 'one');
      expect(await prefs.read('a'), 'one');
    });

    test(
      'writing the same name again replaces the value, one row only',
      () async {
        await prefs.write('a', 'one');
        await prefs.write('a', 'two');
        await prefs.write('a', 'three');
        expect(await prefs.read('a'), 'three');
        expect(await rowCount(), 1);
      },
    );

    test('different names do not disturb each other', () async {
      await prefs.write('a', 'one');
      await prefs.write('b', 'two');
      await prefs.write('a', 'uno');
      expect(await prefs.read('a'), 'uno');
      expect(await prefs.read('b'), 'two');
      expect(await rowCount(), 2);
    });

    test('empty text, unicode and long values survive', () async {
      await prefs.write('empty', '');
      await prefs.write('unicode', 'Tập luyện 💪 — ế');
      final long = 'x' * 5000;
      await prefs.write('long', long);
      expect(await prefs.read('empty'), '');
      expect(await prefs.read('unicode'), 'Tập luyện 💪 — ế');
      expect(await prefs.read('long'), long);
    });
  });

  group('loadIntervalSetup / saveIntervalSetup', () {
    const custom = IntervalConfig(
      prepare: 5,
      work: 35,
      rest: 30,
      rounds: 12,
      sets: 3,
      setRest: 90,
    );

    test('nothing saved gives the initial setup (Tabata)', () async {
      expect(await prefs.loadIntervalSetup(), IntervalSetup.initial);
    });

    test('a saved setup is read back', () async {
      const setup = IntervalSetup(
        preset: IntervalPresetId.custom,
        custom: custom,
      );
      await prefs.saveIntervalSetup(setup);
      expect(await prefs.loadIntervalSetup(), setup);
    });

    test('the chosen preset and the custom workout are kept apart', () async {
      const setup = IntervalSetup(
        preset: IntervalPresetId.hiit3030,
        custom: custom,
      );
      await prefs.saveIntervalSetup(setup);
      final loaded = await prefs.loadIntervalSetup();
      expect(loaded.preset, IntervalPresetId.hiit3030);
      expect(loaded.custom, custom);
      expect(loaded.active, IntervalConfig.hiit3030);
    });

    test('saving again overwrites instead of adding rows', () async {
      await prefs.saveIntervalSetup(IntervalSetup.initial);
      await prefs.saveIntervalSetup(
        const IntervalSetup(preset: IntervalPresetId.custom, custom: custom),
      );
      expect((await prefs.loadIntervalSetup()).custom, custom);
      expect(await rowCount(), 2, reason: 'one row per key');
    });

    test('the two keys and their saved format', () async {
      await prefs.saveIntervalSetup(
        const IntervalSetup(preset: IntervalPresetId.custom, custom: custom),
      );
      expect(await prefs.read('interval.preset'), 'custom');
      expect(jsonDecode((await prefs.read('interval.custom'))!), {
        'prepare': 5,
        'work': 35,
        'rest': 30,
        'rounds': 12,
        'sets': 3,
        'setRest': 90,
      });
    });

    // Dữ liệu hỏng: không crash, trả bài ban đầu.
    group('damaged data falls back to the initial setup', () {
      Future<void> expectInitialAfter({
        String? preset,
        String? customJson,
      }) async {
        if (preset != null) await prefs.write('interval.preset', preset);
        if (customJson != null) {
          await prefs.write('interval.custom', customJson);
        }
        expect(await prefs.loadIntervalSetup(), IntervalSetup.initial);
      }

      test('custom is not JSON', () async {
        await expectInitialAfter(preset: 'custom', customJson: 'not json');
      });

      test('custom is JSON of the wrong shape', () async {
        await expectInitialAfter(preset: 'custom', customJson: '[1,2,3]');
      });

      test('custom has a missing key', () async {
        await expectInitialAfter(
          preset: 'custom',
          customJson: '{"prepare":10,"work":20,"rest":10,"rounds":8,"sets":1}',
        );
      });

      test('custom is outside the allowed range', () async {
        await expectInitialAfter(
          preset: 'custom',
          customJson: '{"prepare":10,"work":20,"rest":10,"rounds":99,"sets":1,"setRest":60}',
        );
      });

      test('custom is damaged even though another preset is chosen', () async {
        await expectInitialAfter(preset: 'hiit3030', customJson: '{');
      });

      test('the preset name is unknown', () async {
        await expectInitialAfter(
          preset: 'marathon',
          customJson: custom.toJson(),
        );
      });

      test('the preset name is empty', () async {
        await expectInitialAfter(preset: '');
      });
    });

    test(
      'only the preset is saved: the custom workout is the default',
      () async {
        await prefs.write('interval.preset', 'hiit3030');
        final loaded = await prefs.loadIntervalSetup();
        expect(loaded.preset, IntervalPresetId.hiit3030);
        expect(loaded.custom, IntervalSetup.initial.custom);
      },
    );

    test(
      'only the custom workout is saved: the preset is the default',
      () async {
        await prefs.write('interval.custom', custom.toJson());
        final loaded = await prefs.loadIntervalSetup();
        expect(loaded.preset, IntervalSetup.initial.preset);
        expect(loaded.custom, custom);
      },
    );

    test(
      'a database that cannot be read still gives the initial setup',
      () async {
        final other = AppDatabase(NativeDatabase.memory());
        final broken = PrefsRepository(other);
        await broken.saveIntervalSetup(
          const IntervalSetup(preset: IntervalPresetId.custom, custom: custom),
        );
        await other.close();

        expect(await broken.loadIntervalSetup(), IntervalSetup.initial);
      },
    );
  });
  group('loadCurrency', () {
    test('nothing saved: writes the fallback and returns it', () async {
      expect(await prefs.loadCurrency(fallback: 'EUR'), 'EUR');
      expect(await prefs.read('money.currency'), 'EUR');
      expect(await rowCount(), 1);
    });

    test('a saved code is kept even when the fallback is different', () async {
      await prefs.write('money.currency', 'JPY');
      expect(await prefs.loadCurrency(fallback: 'USD'), 'JPY');
      expect(await prefs.read('money.currency'), 'JPY', reason: 'not replaced');
      expect(await rowCount(), 1);
    });

    test('once decided, the currency does not follow the fallback', () async {
      expect(await prefs.loadCurrency(fallback: 'EUR'), 'EUR');
      expect(await prefs.loadCurrency(fallback: 'USD'), 'EUR');
      expect(await prefs.loadCurrency(fallback: 'JPY'), 'EUR');
      expect(await rowCount(), 1);
    });

    group('a damaged value is replaced by the fallback', () {
      for (final bad in [
        '',
        ' ',
        'usd',
        'Usd',
        'US',
        'USDD',
        'U\$D',
        ' USD',
        'USD ',
        'USD\n',
        '123',
        'ÉUR',
        'null',
      ]) {
        test('"${bad.replaceAll('\n', r'\n')}"', () async {
          await prefs.write('money.currency', bad);
          expect(await prefs.loadCurrency(fallback: 'EUR'), 'EUR');
          expect(
            await prefs.read('money.currency'),
            'EUR',
            reason: 'overwritten',
          );
          expect(await rowCount(), 1);
        });
      }
    });

    test(
      'three upper-case letters are enough, even for an unusual code',
      () async {
        await prefs.write('money.currency', 'XAU');
        expect(await prefs.loadCurrency(fallback: 'USD'), 'XAU');
      },
    );

    test(
      'a database that cannot be read gives the fallback, no error',
      () async {
        final other = AppDatabase(NativeDatabase.memory());
        final broken = PrefsRepository(other);
        await other.close();

        expect(await broken.loadCurrency(fallback: 'EUR'), 'EUR');
      },
    );

    test(
      'a write that fails is ignored: the fallback is still returned',
      () async {
        await db.customStatement(
          'CREATE TRIGGER fail_prefs_insert BEFORE INSERT ON prefs '
          "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
        );
        expect(await prefs.loadCurrency(fallback: 'EUR'), 'EUR');
        expect(await rowCount(), 0, reason: 'nothing was saved');
      },
    );

    test(
      'a damaged value that cannot be overwritten still gives the fallback',
      () async {
        await prefs.write('money.currency', 'bad');
        await db.customStatement(
          'CREATE TRIGGER fail_prefs_update BEFORE UPDATE ON prefs '
          "BEGIN SELECT RAISE(ABORT, 'simulated write failure'); END;",
        );
        expect(await prefs.loadCurrency(fallback: 'EUR'), 'EUR');
        expect(await prefs.read('money.currency'), 'bad');
      },
    );

    test('does not touch the interval prefs', () async {
      await prefs.write('interval.preset', 'hiit3030');
      await prefs.loadCurrency(fallback: 'USD');
      expect(await prefs.read('interval.preset'), 'hiit3030');
      expect(await rowCount(), 2);
    });
  });
}
