import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/formatting.dart';
import '../../core/services.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/mood_picker.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_chip.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_inline_status.dart';
import '../../ui/components/steady_text_field.dart';
import '../streaks/streak_math.dart';
import 'check_in_rules.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with WidgetsBindingObserver {
  static final _noteFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(
      RegExp(r'[\r\n]+'),
      replacementString: ' ',
    ),
  ];

  final _note = TextEditingController();
  late final AppServices _services;
  late final Stream<List<Habit>> _habits;
  Mood? _mood;
  bool _dirty = false;
  bool _saving = false;
  String? _statusText;
  SteadyStatusTone _statusTone = SteadyStatusTone.info;

  @override
  void initState() {
    super.initState();
    _services = ServicesScope.of(context);
    _habits = _services.habits.watchHabits();
    _services.today.addListener(_onTodayChanged);
    WidgetsBinding.instance.addObserver(this);
    _fill(_services.today.value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _services.today.removeListener(_onTodayChanged);
    _note.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lời chào phụ thuộc giờ nên dựng lại khi app quay về từ nền.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _onTodayChanged() {
    if (!_dirty) _fill(_services.today.value);
  }

  /// Điền sẵn bản đã lưu của [date], trừ khi người dùng đã có bản nháp.
  Future<void> _fill(LocalDate date) async {
    final saved = await _services.checkIns.getForDate(date);
    if (!mounted || _dirty || _services.today.value != date) return;
    setState(() {
      _mood = saved == null ? null : Mood.fromValue(saved.mood);
      _note.text = saved?.note ?? '';
      _statusText = null;
    });
  }

  Future<void> _save() async {
    final mood = _mood;
    if (mood == null || _saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _statusText = null;
    });
    try {
      _services.today.refresh();
      await _services.checkIns.saveForDate(
        date: _services.today.value,
        mood: mood,
        note: _note.text,
      );
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _statusText = l10n.checkInSaved;
        _statusTone = SteadyStatusTone.info;
      });
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusText = l10n.saveError;
          _statusTone = SteadyStatusTone.error;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _greeting(AppLocalizations l10n) {
    return switch (greetingFor(_services.clock.now())) {
      Greeting.morning => l10n.greetingMorning,
      Greeting.afternoon => l10n.greetingAfternoon,
      Greeting.evening => l10n.greetingEvening,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final tag = formatLocaleOf(context);
    return ValueListenableBuilder<LocalDate>(
      valueListenable: _services.today,
      builder: (context, today, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    SteadySpace.s5,
                    SteadySpace.s8,
                    SteadySpace.s5,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatLongDate(today, tag),
                        style: SteadyText.label.copyWith(color: c.inkMuted),
                      ),
                      const SizedBox(height: SteadySpace.s1),
                      Text(
                        _greeting(l10n),
                        style: SteadyText.display.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: SteadySpace.s6),
                      Text(
                        l10n.howWasToday,
                        style: SteadyText.headline.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: SteadySpace.s3),
                      MoodPicker(
                        value: _mood,
                        onChanged: (mood) => setState(() {
                          _mood = mood;
                          _dirty = true;
                          _statusText = null;
                        }),
                      ),
                      const SizedBox(height: SteadySpace.s6),
                      Text(
                        l10n.noteLabel,
                        style: SteadyText.headline.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: SteadySpace.s2),
                      SteadyTextField(
                        controller: _note,
                        minLines: 3,
                        maxLines: 3,
                        maxLength: kCheckInNoteMaxChars,
                        textInputAction: TextInputAction.done,
                        inputFormatters: _noteFormatters,
                        // _dirty không ảnh hưởng giao diện: chỉ dựng lại cả màn
                        // hình khi có trạng thái cần xoá, không phải mỗi phím.
                        onChanged: (_) {
                          _dirty = true;
                          if (_statusText != null) {
                            setState(() => _statusText = null);
                          }
                        },
                      ),
                      const SizedBox(height: SteadySpace.s2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _note,
                          builder: (context, value, _) => Text(
                            l10n.noteCounter(
                              value.text.characters.length,
                              kCheckInNoteMaxChars,
                            ),
                            style: SteadyText.caption.copyWith(
                              color: c.inkMuted,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      StreamBuilder<List<Habit>>(
                        stream: _habits,
                        builder: (context, snapshot) {
                          final habits = snapshot.data;
                          if (habits == null || habits.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final main = habits.first;
                          return Padding(
                            padding: const EdgeInsets.only(top: SteadySpace.s6),
                            child: SteadyChip(
                              label: l10n.streakChip(
                                daysClean(main.cleanSince, today),
                                main.name,
                              ),
                              tone: SteadyChipTone.tide,
                              icon: SteadyIcons.sprout,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SteadySpace.s5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_statusText != null) ...[
                      SteadyInlineStatus(
                        message: _statusText!,
                        tone: _statusTone,
                      ),
                      const SizedBox(height: SteadySpace.s3),
                    ],
                    SteadyButton(
                      label: l10n.saveCheckIn,
                      onPressed: _mood == null || _saving ? null : _save,
                      variant: SteadyButtonVariant.primary,
                      block: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
