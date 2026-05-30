import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSliderWidget extends StatefulWidget {
  final DateTime earliest;
  final DateTime latest;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;

  const TimeSliderWidget({
    super.key,
    required this.earliest,
    required this.latest,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TimeSliderWidget> createState() => _TimeSliderWidgetState();
}

class _TimeSliderWidgetState extends State<TimeSliderWidget> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = _dateRangeToValues();
  }

  @override
  void didUpdateWidget(TimeSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _values = _dateRangeToValues();
    }
  }

  RangeValues _dateRangeToValues() {
    if (widget.value == null) {
      return RangeValues(0, _totalDays().toDouble());
    }
    final start = widget.value!.start
        .difference(widget.earliest)
        .inDays
        .toDouble()
        .clamp(0.0, _totalDays().toDouble());
    final end = widget.value!.end
        .difference(widget.earliest)
        .inDays
        .toDouble()
        .clamp(0.0, _totalDays().toDouble());
    return RangeValues(start, end);
  }

  int _totalDays() {
    return widget.latest.difference(widget.earliest).inDays.clamp(1, 9999);
  }

  DateTime _valueToDate(double val) {
    return widget.earliest.add(Duration(days: val.round()));
  }

  String _formatDate(DateTime d) => DateFormat('MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final total = _totalDays().toDouble();
    final startDate = _valueToDate(_values.start);
    final endDate = _valueToDate(_values.end);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(startDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Time Filter',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _formatDate(endDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF6B6B),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFFF6B6B).withOpacity(0.3),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 8,
              ),
            ),
            child: RangeSlider(
              values: RangeValues(
                _values.start.clamp(0.0, total),
                _values.end.clamp(0.0, total),
              ),
              min: 0,
              max: total,
              divisions: total.round().clamp(1, 365),
              onChanged: (v) {
                setState(() => _values = v);
                widget.onChanged(DateTimeRange(
                  start: _valueToDate(v.start),
                  end: _valueToDate(v.end),
                ));
              },
              onChangeEnd: (v) {
                final range = DateTimeRange(
                  start: _valueToDate(v.start),
                  end: _valueToDate(v.end),
                );
                final isFullRange = v.start <= 0 && v.end >= total;
                widget.onChanged(isFullRange ? null : range);
              },
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
