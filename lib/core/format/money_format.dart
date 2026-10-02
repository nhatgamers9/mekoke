import 'package:intl/intl.dart';

import 'region_currency.dart';

/// Định dạng tiền theo locale và tiền tệ. Chỉ định dạng số dương, không bao
/// giờ thêm dấu: dấu "−" do nơi hiển thị thêm.
class MoneyFormat {
  /// Dùng lại cùng một đối tượng cho mỗi cặp ([localeTag], [currencyCode]).
  factory MoneyFormat(String localeTag, String currencyCode) =>
      _cache.putIfAbsent((
        localeTag,
        currencyCode,
      ), () => MoneyFormat._(localeTag, currencyCode));

  MoneyFormat._(String localeTag, this.currencyCode)
    : _numTag = _numberTag(localeTag),
      decimals = decimalsFor(currencyCode);

  static final _cache = <(String, String), MoneyFormat>{};

  static String _numberTag(String tag) =>
      Intl.verifiedLocale(
        tag,
        NumberFormat.localeExists,
        onFailure: (_) => 'en',
      ) ??
      'en';

  final String currencyCode;
  final String _numTag;

  // NumberFormat phải phân tích mẫu mỗi lần tạo, nên giữ lại theo số chữ số.
  final _formats = <int, NumberFormat>{};

  /// Số chữ số thập phân của tiền tệ (2 với USD, 0 với JPY).
  final int decimals;

  late final String decimalSeparator = NumberFormat.decimalPattern(_numTag)
      .symbols
      .DECIMAL_SEP;

  /// [minor] là số tiền theo đơn vị nhỏ nhất: 1240 ra "$12.40" với USD.
  String format(int minor) => formatScaled(minor, decimals);

  /// `value / 10^fractionDigits`, đúng [fractionDigits] chữ số thập phân, kèm
  /// ký hiệu tiền tệ.
  String formatScaled(int value, int fractionDigits) {
    final format = _formats.putIfAbsent(
      fractionDigits,
      () => NumberFormat.simpleCurrency(
        locale: _numTag,
        name: currencyCode,
        decimalDigits: fractionDigits,
      ),
    );
    var divisor = 1;
    for (var i = 0; i < fractionDigits; i++) {
      divisor *= 10;
    }
    return format.format(value / divisor);
  }

  /// Subtag vùng in hoa của [tag] ("AR" với `es_AR` và `zh-Hant-TW`), bỏ qua
  /// ngôn ngữ và script; không có thì `null`.
  static String? _regionOf(String tag) {
    final parts = tag.split(RegExp('[-_]')).skip(1).toList();
    if (parts.isNotEmpty && RegExp(r'^[A-Za-z]{4}$').hasMatch(parts.first)) {
      parts.removeAt(0);
    }
    if (parts.isEmpty) return null;
    final part = parts.first;
    if (RegExp(r'^[A-Za-z]{2}$').hasMatch(part)) return part.toUpperCase();
    if (RegExp(r'^[0-9]{3}$').hasMatch(part)) return part;
    return null;
  }

  /// Tiền tệ mặc định của máy có locale [deviceLocaleTag]: tra bảng theo vùng
  /// trước ([kRegionCurrency]), rồi tới intl theo locale, cuối cùng là USD.
  static String currencyForLocale(String deviceLocaleTag) {
    final region = _regionOf(deviceLocaleTag);
    final byRegion = region == null ? null : kRegionCurrency[region];
    if (byRegion != null) return byRegion;
    return NumberFormat.simpleCurrency(locale: _numberTag(deviceLocaleTag))
            .currencyName ??
        'USD';
  }

  static int decimalsFor(String currencyCode) =>
      NumberFormat.simpleCurrency(
        locale: 'en',
        name: currencyCode,
      ).decimalDigits ??
      2;
}
