import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:steady/features/timer/interval_config.dart';

void main() {
  group('IntervalField', () {
    test('ranges', () {
      expect(
        {for (final f in IntervalField.values) f: (f.min, f.max)},
        {
          IntervalField.prepare: (0, 60),
          IntervalField.work: (5, 600),
          IntervalField.rest: (0, 600),
          IntervalField.rounds: (1, 50),
          IntervalField.sets: (1, 10),
          IntervalField.setRest: (0, 600),
        },
      );
    });

    test('only rounds and sets are counts, the rest are seconds', () {
      expect(IntervalField.values.where((f) => !f.isTime), [
        IntervalField.rounds,
        IntervalField.sets,
      ]);
    });
  });

  group('stepUp / stepDown for times', () {
    test('5 seconds below one minute', () {
      expect(stepUp(IntervalField.work, 20), 25);
      expect(stepUp(IntervalField.work, 5), 10);
      expect(stepDown(IntervalField.work, 25), 20);
      expect(stepDown(IntervalField.rest, 10), 5);
    });

    test('15 seconds above one minute', () {
      expect(stepUp(IntervalField.work, 75), 90);
      expect(stepDown(IntervalField.work, 90), 75);
      expect(stepUp(IntervalField.setRest, 60 * 5), 315);
    });

    test('the step changes around 60: 55 -> 60 -> 75 and 75 -> 60 -> 55', () {
      expect(stepUp(IntervalField.work, 55), 60);
      expect(stepUp(IntervalField.work, 60), 75);
      expect(stepDown(IntervalField.work, 75), 60);
      expect(stepDown(IntervalField.work, 60), 55);
    });

    test('going up then down returns to the same value (away from limits)', () {
      var v = 5;
      final seen = <int>[v];
      while (v < 300) {
        final up = stepUp(IntervalField.work, v);
        expect(stepDown(IntervalField.work, up), v, reason: 'from $v');
        v = up;
        seen.add(v);
      }
      expect(seen.take(14), [
        5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 75, 90, //
      ]);
    });

    test('never goes below min or above max', () {
      expect(stepDown(IntervalField.work, 5), 5);
      expect(stepDown(IntervalField.prepare, 0), 0);
      expect(stepDown(IntervalField.rest, 0), 0);
      expect(stepDown(IntervalField.setRest, 0), 0);
      expect(stepUp(IntervalField.work, 600), 600);
      expect(stepUp(IntervalField.work, 595), 600);
      expect(stepUp(IntervalField.prepare, 60), 60);
      expect(stepUp(IntervalField.prepare, 55), 60);
      expect(stepUp(IntervalField.rest, 600), 600);
      expect(stepUp(IntervalField.setRest, 600), 600);
    });

    test('prepare goes 0 -> 5 -> ... -> 60 and stops', () {
      var v = 0;
      final seen = <int>[v];
      for (var i = 0; i < 20; i++) {
        v = stepUp(IntervalField.prepare, v);
        seen.add(v);
      }
      expect(seen.take(13), [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]);
      expect(seen.toSet().last, 60);
      expect(seen.skip(12).toSet(), {60});
    });
  });

  group('stepUp / stepDown for counts', () {
    test('plus or minus one', () {
      expect(stepUp(IntervalField.rounds, 8), 9);
      expect(stepDown(IntervalField.rounds, 8), 7);
      expect(stepUp(IntervalField.sets, 1), 2);
      expect(stepDown(IntervalField.sets, 2), 1);
    });

    test('clamped at the limits', () {
      expect(stepDown(IntervalField.rounds, 1), 1);
      expect(stepUp(IntervalField.rounds, 50), 50);
      expect(stepDown(IntervalField.sets, 1), 1);
      expect(stepUp(IntervalField.sets, 10), 10);
    });
  });

  group('IntervalConfig', () {
    test('the two built-in workouts', () {
      const tabata = IntervalConfig.tabata;
      expect(
        [
          tabata.prepare,
          tabata.work,
          tabata.rest,
          tabata.rounds,
          tabata.sets,
          tabata.setRest,
        ],
        [10, 20, 10, 8, 1, 60],
      );
      const hiit = IntervalConfig.hiit3030;
      expect(
        [
          hiit.prepare,
          hiit.work,
          hiit.rest,
          hiit.rounds,
          hiit.sets,
          hiit.setRest,
        ],
        [10, 30, 30, 10, 1, 60],
      );
    });

    test('valueOf and withValue address one field and leave the others', () {
      const c = IntervalConfig.tabata;
      expect(c.valueOf(IntervalField.work), 20);
      expect(c.valueOf(IntervalField.rounds), 8);
      final changed = c.withValue(IntervalField.work, 35);
      expect(changed.work, 35);
      expect(changed.valueOf(IntervalField.work), 35);
      expect(changed.rest, c.rest);
      expect(changed.rounds, c.rounds);
      expect(changed.prepare, c.prepare);
      expect(changed.sets, c.sets);
      expect(changed.setRest, c.setRest);
      expect(c.work, 20, reason: 'the original does not change');
      for (final f in IntervalField.values) {
        expect(c.withValue(f, c.valueOf(f)), c);
      }
    });

    test('== and hashCode compare every field', () {
      const a = IntervalConfig.tabata;
      final b = IntervalConfig.tabata.withValue(IntervalField.work, 20);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      for (final f in IntervalField.values) {
        final other = a.withValue(f, a.valueOf(f) + 1);
        expect(a == other, isFalse, reason: f.name);
      }
      expect(IntervalConfig.tabata, isNot(IntervalConfig.hiit3030));
    });

    test('isValid is true only inside every range', () {
      expect(IntervalConfig.tabata.isValid, isTrue);
      expect(IntervalConfig.hiit3030.isValid, isTrue);
      for (final f in IntervalField.values) {
        expect(
          IntervalConfig.tabata.withValue(f, f.min).isValid,
          isTrue,
          reason: '${f.name} at min',
        );
        expect(
          IntervalConfig.tabata.withValue(f, f.max).isValid,
          isTrue,
          reason: '${f.name} at max',
        );
        expect(
          IntervalConfig.tabata.withValue(f, f.min - 1).isValid,
          isFalse,
          reason: '${f.name} below min',
        );
        expect(
          IntervalConfig.tabata.withValue(f, f.max + 1).isValid,
          isFalse,
          reason: '${f.name} above max',
        );
      }
    });
  });

  group('IntervalConfig JSON', () {
    test('round trip', () {
      for (final c in [
        IntervalConfig.tabata,
        IntervalConfig.hiit3030,
        const IntervalConfig(
          prepare: 0,
          work: 600,
          rest: 0,
          rounds: 50,
          sets: 10,
          setRest: 600,
        ),
        const IntervalConfig(
          prepare: 60,
          work: 5,
          rest: 600,
          rounds: 1,
          sets: 1,
          setRest: 0,
        ),
      ]) {
        expect(IntervalConfig.tryFromJson(c.toJson()), c);
      }
    });

    test('the stored shape is a flat object of whole seconds and counts', () {
      expect(jsonDecode(IntervalConfig.tabata.toJson()), {
        'prepare': 10,
        'work': 20,
        'rest': 10,
        'rounds': 8,
        'sets': 1,
        'setRest': 60,
      });
    });

    test('broken text gives null, never an exception', () {
      for (final raw in [
        '',
        'not json',
        '{',
        '[]',
        '123',
        'null',
        '"text"',
        '{"prepare":10,',
      ]) {
        expect(IntervalConfig.tryFromJson(raw), isNull, reason: raw);
      }
    });

    test('a missing key gives null', () {
      for (final f in IntervalField.values) {
        final map = jsonDecode(IntervalConfig.tabata.toJson()) as Map;
        map.remove(f.name);
        expect(
          IntervalConfig.tryFromJson(jsonEncode(map)),
          isNull,
          reason: 'missing ${f.name}',
        );
      }
    });

    test('a value of the wrong type gives null', () {
      for (final bad in ['"8"', 'null', '8.5', 'true', '[8]']) {
        expect(
          IntervalConfig.tryFromJson(
            '{"prepare":10,"work":20,"rest":10,"rounds":$bad,'
            '"sets":1,"setRest":60}',
          ),
          isNull,
          reason: 'rounds = $bad',
        );
      }
    });

    test('a value outside the range gives null', () {
      for (final f in IntervalField.values) {
        for (final bad in [f.min - 1, f.max + 1, -1]) {
          final map = jsonDecode(IntervalConfig.tabata.toJson()) as Map;
          map[f.name] = bad;
          expect(
            IntervalConfig.tryFromJson(jsonEncode(map)),
            isNull,
            reason: '${f.name} = $bad',
          );
        }
      }
    });
  });

  group('IntervalSetup', () {
    test('the initial setup is Tabata with a Tabata custom workout', () {
      expect(IntervalSetup.initial.preset, IntervalPresetId.tabata);
      expect(IntervalSetup.initial.custom, IntervalConfig.tabata);
      expect(IntervalSetup.initial.active, IntervalConfig.tabata);
    });

    test('active follows the chosen preset', () {
      const custom = IntervalConfig(
        prepare: 5,
        work: 40,
        rest: 20,
        rounds: 6,
        sets: 2,
        setRest: 45,
      );
      expect(
        const IntervalSetup(
          preset: IntervalPresetId.tabata,
          custom: custom,
        ).active,
        IntervalConfig.tabata,
      );
      expect(
        const IntervalSetup(
          preset: IntervalPresetId.hiit3030,
          custom: custom,
        ).active,
        IntervalConfig.hiit3030,
      );
      expect(
        const IntervalSetup(
          preset: IntervalPresetId.custom,
          custom: custom,
        ).active,
        custom,
      );
    });

    test('== and hashCode', () {
      const a = IntervalSetup(
        preset: IntervalPresetId.custom,
        custom: IntervalConfig.hiit3030,
      );
      const b = IntervalSetup(
        preset: IntervalPresetId.custom,
        custom: IntervalConfig.hiit3030,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const IntervalSetup(
            preset: IntervalPresetId.tabata,
            custom: IntervalConfig.hiit3030,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const IntervalSetup(
            preset: IntervalPresetId.custom,
            custom: IntervalConfig.tabata,
          ),
        ),
      );
    });

    test('preset names are stable (they are saved to disk)', () {
      expect(IntervalPresetId.values.map((p) => p.name), [
        'tabata',
        'hiit3030',
        'custom',
      ]);
    });
  });
}
