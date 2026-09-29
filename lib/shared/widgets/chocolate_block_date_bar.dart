import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/clock.dart';
import '../../core/format.dart';

/// Horizontal chocolate block date bar with:
/// - Permanently fixed focus position at the viewport center (dates scroll through it)
/// - The date currently passing through the fixed focus position receives 1.10x size & chocolate color
/// - Clean full-date block snapping on horizontal swipes
/// - Small swipe moves exactly one full date block
/// - Subtle tick / toggle sound on successful date transition
/// - Tiny calendar jump button at top-right
/// - Independent Today indicator
class ChocolateBlockDateBar extends StatefulWidget {
  const ChocolateBlockDateBar({
    super.key,
    required this.selected,
    required this.now,
    required this.onDateSelected,
  });

  final DateTime selected;
  final DateTime now;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<ChocolateBlockDateBar> createState() => _ChocolateBlockDateBarState();
}

class _ChocolateBlockDateBarState extends State<ChocolateBlockDateBar> {
  late final ScrollController _scrollController;
  late DateTime _startDay;
  late List<DateTime> _days;

  bool _isScrolling = false;
  bool _isUserDragging = false;
  double _dragStartOffset = 0.0;
  int _dragStartIndex = 0;

  static const double itemWidth = 84.0; // 76 card width + 8 right padding
  static const double cardWidth = 76.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initDays();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(widget.selected, animate: false);
    });
  }

  void _initDays([DateTime? focusDate]) {
    final center = focusDate ?? widget.now;
    _startDay = dateOnly(center).subtract(const Duration(days: 30));
    _days = List.generate(90, (i) => _startDay.add(Duration(days: i)));
  }

  int get currentCenterIndex {
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) {
      final idx = _days.indexWhere((d) => sameDay(d, widget.selected));
      return idx != -1 ? idx : 30;
    }
    return (_scrollController.offset / itemWidth).round().clamp(0, _days.length - 1);
  }

  @override
  void didUpdateWidget(covariant ChocolateBlockDateBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!sameDay(oldWidget.now, widget.now)) {
      _initDays();
    }
    if (!sameDay(oldWidget.selected, widget.selected)) {
      if (!_isUserDragging) {
        _scrollToDate(widget.selected, animate: true);
      }
    }
  }

  void _scrollToDate(DateTime date, {bool animate = true}) {
    if (!_days.any((d) => sameDay(d, date))) {
      _initDays(date);
      setState(() {});
    }
    if (!_scrollController.hasClients || !_scrollController.position.hasContentDimensions) return;
    final index = _days.indexWhere((d) => sameDay(d, date));
    if (index == -1) return;
    final targetOffset = index * itemWidth;
    final clamped = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
    if (animate) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  void _playDateTransitionSound() {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _openCalendarPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selected,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: isDark ? const Color(0xFF8D6E63) : const Color(0xFF4E342E),
              onPrimary: Colors.white,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      final newDate = dateOnly(picked);
      widget.onDateSelected(newDate);
      _scrollToDate(newDate, animate: true);
      _playDateTransitionSound();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const chocolateSubtle = Color(0xFFEFEBE9);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiny calendar jump button placed slightly upward in the gap above the sliding bar
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openCalendarPicker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2422) : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.calendar,
                    size: 15,
                    color: isDark ? const Color(0xFFD7CCC8) : const Color(0xFF5D4037),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 86,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final horizontalPadding = (viewportWidth - cardWidth) / 2.0;

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification) {
                    _isScrolling = true;
                    if (notification.dragDetails != null) {
                      _isUserDragging = true;
                      _dragStartOffset = _scrollController.offset;
                      _dragStartIndex = (_dragStartOffset / itemWidth)
                          .round()
                          .clamp(0, _days.length - 1);
                    }
                    setState(() {});
                  } else if (notification is ScrollUpdateNotification) {
                    if (!_isScrolling) {
                      _isScrolling = true;
                    }
                  } else if (notification is ScrollEndNotification) {
                    _isScrolling = false;
                    if (_isUserDragging && _scrollController.hasClients) {
                      _isUserDragging = false;
                      final currentOffset = _scrollController.offset;
                      final delta = currentOffset - _dragStartOffset;
                      int targetIndex;

                      if (delta.abs() < 50.0) {
                        // Intentional swipe snapping:
                        // Small swipe moves exactly one full date block in swipe direction
                        if (delta > 1.0) {
                          targetIndex = _dragStartIndex + 1;
                        } else if (delta < -1.0) {
                          targetIndex = _dragStartIndex - 1;
                        } else {
                          targetIndex = _dragStartIndex;
                        }
                      } else {
                        // Faster swipe / fling: snap to whichever date is aligned with the fixed focus position
                        targetIndex = (currentOffset / itemWidth).round();
                      }

                      targetIndex = targetIndex.clamp(0, _days.length - 1);
                      final targetOffset = targetIndex * itemWidth;

                      if ((_scrollController.offset - targetOffset).abs() > 0.5) {
                        _scrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        );
                      }

                      if (targetIndex != _dragStartIndex) {
                        final newDay = _days[targetIndex];
                        widget.onDateSelected(newDay);
                        _playDateTransitionSound();
                      }
                    }
                    setState(() {});
                  }
                  return false;
                },
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, _) {
                    final scrollOffset = _scrollController.hasClients && _scrollController.position.hasContentDimensions
                        ? _scrollController.offset
                        : (_days.indexWhere((d) => sameDay(d, widget.selected)) * itemWidth).toDouble();

                    final cardBg = isDark ? const Color(0xFF231D1B) : chocolateSubtle;
                    final textColor = isDark ? Colors.white : const Color(0xFF2E1C14);
                    final weekdayColor = isDark ? Colors.grey[400]! : const Color(0xFF6D4C41);
                    final animDuration = _isScrolling ? Duration.zero : const Duration(milliseconds: 140);

                    return ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      itemCount: _days.length,
                      itemBuilder: (ctx, i) {
                        final day = _days[i];
                        final cardDx = (i * itemWidth - scrollOffset).abs();
                        // Magnification curve centered at the fixed viewport point (no extra color)
                        final factor = (1.0 - (cardDx / 84.0)).clamp(0.0, 1.0);
                        final smoothT = factor * factor * (3.0 - 2.0 * factor);
                        final scale = 1.0 + 0.20 * smoothT;

                        final isToday = sameDay(day, widget.now);

                        // Today Indicator remains separate and attached to Today's date
                        Border? border;
                        if (isToday) {
                          border = Border.all(
                            color: isDark ? const Color(0xFF8D6E63) : const Color(0xFF6D4C41),
                            width: 1.6,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Center(
                            child: AnimatedScale(
                              scale: scale,
                              duration: animDuration,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.center,
                              child: InkWell(
                                onTap: () {
                                  _isUserDragging = false;
                                  _isScrolling = false;
                                  HapticFeedback.selectionClick();
                                  widget.onDateSelected(day);
                                  _scrollToDate(day, animate: true);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: cardWidth,
                                  height: 72,
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: border,
                                    boxShadow: smoothT > 0.08
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12 * smoothT),
                                              blurRadius: 8 * smoothT,
                                              offset: Offset(0, 2 * smoothT),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isToday)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 2),
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white24 : const Color(0xFF8D6E63).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'TODAY',
                                              style: TextStyle(
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                                color: isDark ? Colors.grey[300] : const Color(0xFF4E342E),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          '${day.day} ${Fmt.month(day).substring(0, 3)}',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 12.0 + (2.0 * smoothT),
                                            fontWeight: smoothT > 0.5 ? FontWeight.w900 : FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          Fmt.weekday(day),
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 9.0 + (1.0 * smoothT),
                                            fontWeight: smoothT > 0.5 ? FontWeight.w700 : FontWeight.w400,
                                            color: weekdayColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
