import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/core/theme/tokens.dart';
import 'package:steady/core/theme/typography.dart';

/// Màu theo tên token trong tokens.json (kebab-case).
Map<String, Color> _colorsByToken(SteadyColors c) => {
  'bg': c.bg,
  'surface': c.surface,
  'surface-2': c.surface2,
  'line': c.line,
  'line-strong': c.lineStrong,
  'ink': c.ink,
  'ink-muted': c.inkMuted,
  'amber': c.amber,
  'on-amber': c.onAmber,
  'amber-soft': c.amberSoft,
  'tide': c.tide,
  'on-tide': c.onTide,
  'tide-soft': c.tideSoft,
  'rose': c.rose,
  'on-rose': c.onRose,
  'rose-soft': c.roseSoft,
};

const _textStyles = <String, TextStyle>{
  'count-xl': SteadyText.countXl,
  'timer-xl': SteadyText.timerXl,
  'display': SteadyText.display,
  'title': SteadyText.title,
  'headline': SteadyText.headline,
  'body': SteadyText.body,
  'body-strong': SteadyText.bodyStrong,
  'label': SteadyText.label,
  'caption': SteadyText.caption,
  'overline': SteadyText.overline,
  'money-xl': SteadyText.moneyXl,
  'count-gym': SteadyText.countGym,
  'stat': SteadyText.stat,
};

/// "#rrggbb" -> 0xFFrrggbb.
int _hexRgb(String css) {
  expect(css, matches(RegExp(r'^#[0-9a-fA-F]{6}$')), reason: css);
  return 0xFF000000 | int.parse(css.substring(1), radix: 16);
}

/// "0 -12px 40px #rrggbbaa" (hoặc #rrggbb, tức đục hẳn) -> 0xAArrggbb.
/// CSS đặt alpha ở cuối, Flutter đặt ở đầu.
int _shadowColor(String css) {
  final match = RegExp(r'#([0-9a-fA-F]{8}|[0-9a-fA-F]{6})$').firstMatch(css);
  expect(match, isNotNull, reason: css);
  final hex = match!.group(1)!;
  if (hex.length == 6) return 0xFF000000 | int.parse(hex, radix: 16);
  final rgba = int.parse(hex, radix: 16);
  final rgb = rgba >> 8;
  final alpha = rgba & 0xFF;
  return (alpha << 24) | rgb;
}

double _px(String css) {
  expect(css, endsWith('px'));
  return double.parse(css.substring(0, css.length - 2));
}

double _em(String css) {
  expect(css, endsWith('em'));
  return double.parse(css.substring(0, css.length - 2));
}

void main() {
  late Map<String, dynamic> tokens;

  setUpAll(() {
    tokens = jsonDecode(
      File('design/steady-ds/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  group('colors match tokens.json for all three themes', () {
    final themes = {
      'dark': SteadyColors.dark,
      'light': SteadyColors.light,
      'bedtime': SteadyColors.bedtime,
    };

    test('every json color token is mapped, and the mapping has no extras', () {
      final names = [
        for (final t in tokens['color']['tokens'] as List) t['name'] as String,
      ];
      expect(
        names.toSet(),
        _colorsByToken(SteadyColors.dark).keys.toSet(),
        reason: 'new/removed token in tokens.json needs a SteadyColors field',
      );
    });

    for (final entry in themes.entries) {
      test('${entry.key} theme', () {
        final actual = _colorsByToken(entry.value);
        for (final t in tokens['color']['tokens'] as List) {
          final name = t['name'] as String;
          final expected = _hexRgb(t['value'][entry.key] as String);
          expect(
            actual[name]!.toARGB32(),
            expected,
            reason:
                '$name (${entry.key}): expected '
                '0x${expected.toRadixString(16)}',
          );
        }
      });

      test('${entry.key} sheet shadow converts #RRGGBBAA to 0xAARRGGBB', () {
        final shadow = (tokens['shadow']['tokens'] as List).firstWhere(
          (t) => t['name'] == 'shadow-sheet',
        );
        final expected = _shadowColor(shadow['value'][entry.key] as String);
        expect(entry.value.sheetShadow.toARGB32(), expected);
      });
    }

    test('sheetShadow absolute values from the plan', () {
      expect(SteadyColors.dark.sheetShadow.toARGB32(), 0xB3000000);
      expect(SteadyColors.light.sheetShadow.toARGB32(), 0x241C1916);
      expect(SteadyColors.bedtime.sheetShadow.toARGB32(), 0xFF000000);
    });
  });

  group('SteadyColors ThemeExtension', () {
    test('copyWith with no arguments keeps every color', () {
      final copy = SteadyColors.dark.copyWith();
      expect(
        _colorsByToken(copy).map((k, v) => MapEntry(k, v.toARGB32())),
        _colorsByToken(SteadyColors.dark)
            .map((k, v) => MapEntry(k, v.toARGB32())),
      );
      expect(copy.sheetShadow, SteadyColors.dark.sheetShadow);
    });

    test('copyWith replaces only the named field', () {
      const red = Color(0xFFFF0000);
      final copy = SteadyColors.dark.copyWith(amber: red);
      expect(copy.amber, red);
      expect(copy.tide, SteadyColors.dark.tide);
      expect(copy.bg, SteadyColors.dark.bg);
    });

    test('lerp at 0 and 1 returns the endpoints', () {
      final at0 = SteadyColors.dark.lerp(SteadyColors.light, 0);
      final at1 = SteadyColors.dark.lerp(SteadyColors.light, 1);
      expect(
        _colorsByToken(at0).map((k, v) => MapEntry(k, v.toARGB32())),
        _colorsByToken(SteadyColors.dark)
            .map((k, v) => MapEntry(k, v.toARGB32())),
      );
      expect(
        _colorsByToken(at1).map((k, v) => MapEntry(k, v.toARGB32())),
        _colorsByToken(SteadyColors.light)
            .map((k, v) => MapEntry(k, v.toARGB32())),
      );
      expect(at1.sheetShadow, SteadyColors.light.sheetShadow);
    });

    test('lerp moves every field between the two themes', () {
      final mid = SteadyColors.dark.lerp(SteadyColors.light, 0.5);
      expect(
        mid.bg,
        Color.lerp(SteadyColors.dark.bg, SteadyColors.light.bg, 0.5),
      );
      expect(
        mid.rose,
        Color.lerp(SteadyColors.dark.rose, SteadyColors.light.rose, 0.5),
      );
    });

    test('lerp with a foreign extension returns this', () {
      expect(
        identical(SteadyColors.dark.lerp(null, 0.5), SteadyColors.dark),
        isTrue,
      );
    });
  });

  group('type scale matches tokens.json', () {
    final styles = <String, Map<String, dynamic>>{};
    final families = <String, String>{};

    setUpAll(() {
      for (final g in tokens['type']['groups'] as List) {
        for (final s in g['styles'] as List) {
          styles[s['name'] as String] = {...s as Map<String, dynamic>};
          families[s['name'] as String] = g['family'] as String;
        }
      }
    });

    test('every json style is mapped, and the mapping has no extras', () {
      expect(styles.keys.toSet(), _textStyles.keys.toSet());
    });

    for (final name in _textStyles.keys) {
      test('$name: size, line height, weight, tracking, family', () {
        final json = styles[name]!;
        final style = _textStyles[name]!;
        final size = _px(json['fontSize'] as String);
        final lineHeight = _px(json['lineHeight'] as String);
        final weight = json['fontWeight'] as int;

        expect(style.fontSize, size);
        expect(style.height, closeTo(lineHeight / size, 1e-9));
        expect(style.fontWeight, FontWeight.values[(weight ~/ 100) - 1]);
        expect(
          style.fontVariations,
          contains(FontVariation('wght', weight.toDouble())),
          reason: 'variable font needs an explicit wght axis',
        );
        final tracking = json['letterSpacing'] == null
            ? 0.0
            : _em(json['letterSpacing'] as String) * size;
        expect(style.letterSpacing ?? 0.0, closeTo(tracking, 1e-9));
        expect(
          style.fontFamily,
          families[name] == 'serif' ? 'Newsreader' : 'Figtree',
        );
        expect(
          style.color,
          isNull,
          reason: 'SteadyText styles must not carry a color',
        );
      });
    }

    test('only count-gym and stat use tabular figures', () {
      for (final entry in _textStyles.entries) {
        final tabular =
            entry.value.fontFeatures?.contains(
              const FontFeature.tabularFigures(),
            ) ??
            false;
        expect(
          tabular,
          entry.key == 'count-gym' || entry.key == 'stat',
          reason: entry.key,
        );
      }
    });
  });

  group('spacing, radius and size tokens', () {
    Map<String, double> read(String group) => {
      for (final t in tokens[group]['tokens'] as List)
        t['name'] as String: _px(t['value'] as String),
    };

    test('spacing', () {
      final actual = {
        'space-1': SteadySpace.s1,
        'space-2': SteadySpace.s2,
        'space-3': SteadySpace.s3,
        'space-4': SteadySpace.s4,
        'space-5': SteadySpace.s5,
        'space-6': SteadySpace.s6,
        'space-8': SteadySpace.s8,
        'space-12': SteadySpace.s12,
      };
      expect(actual, read('spacing'));
    });

    test('radius', () {
      final actual = {
        'radius-sm': SteadyRadius.sm,
        'radius-md': SteadyRadius.md,
        'radius-lg': SteadyRadius.lg,
        'radius-xl': SteadyRadius.xl,
        'radius-full': SteadyRadius.full,
      };
      expect(actual, read('radius'));
    });

    test('size', () {
      final actual = {
        'size-tap': SteadySize.tap,
        'size-button': SteadySize.button,
        'size-play': SteadySize.play,
        'size-ring': SteadySize.ring,
        'size-ring-stroke': SteadySize.ringStroke,
        'size-tabbar': SteadySize.tabbar,
      };
      expect(actual, read('size'));
    });

    test('buttonMd is 44, matching .st-btn-md in bundle.css', () {
      final css = File('design/steady-ds/components/bundle.css')
          .readAsStringSync();
      expect(css, contains('.st-btn-md { height: 44px;'));
      expect(SteadySize.buttonMd, 44);
    });
  });
}
