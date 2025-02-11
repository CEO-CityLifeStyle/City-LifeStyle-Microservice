import 'package:flutter/material.dart';
import '../models/place.dart';

class OpeningHoursWidget extends StatefulWidget {
  final Map<String, DayHours> openingHours;
  final Function(Map<String, DayHours>) onChanged;

  const OpeningHoursWidget({
    super.key,
    required this.openingHours,
    required this.onChanged,
  });

  @override
  State<OpeningHoursWidget> createState() => _OpeningHoursWidgetState();
}

class _OpeningHoursWidgetState extends State<OpeningHoursWidget> {
  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay? initialTime) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Closed';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Widget _buildDayRow(String day) {
    final dayHours = widget.openingHours[day]!;
    final openTime = _parseTime(dayHours.open);
    final closeTime = _parseTime(dayHours.close);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day.substring(0, 1).toUpperCase() + day.substring(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Switch(
            value: openTime != null,
            onChanged: (value) {
              final updatedHours = Map<String, DayHours>.from(widget.openingHours);
              if (value) {
                updatedHours[day] = DayHours(
                  open: '09:00',
                  close: '17:00',
                );
              } else {
                updatedHours[day] = DayHours();
              }
              widget.onChanged(updatedHours);
            },
          ),
          if (openTime != null) ...[
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final time = await _selectTime(context, openTime);
                  if (time != null) {
                    final updatedHours = Map<String, DayHours>.from(widget.openingHours);
                    updatedHours[day] = DayHours(
                      open: _formatTime(time),
                      close: dayHours.close,
                    );
                    widget.onChanged(updatedHours);
                  }
                },
                child: Text(_formatTime(openTime)),
              ),
            ),
            const Text('to'),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final time = await _selectTime(context, closeTime);
                  if (time != null) {
                    final updatedHours = Map<String, DayHours>.from(widget.openingHours);
                    updatedHours[day] = DayHours(
                      open: dayHours.open,
                      close: _formatTime(time),
                    );
                    widget.onChanged(updatedHours);
                  }
                },
                child: Text(_formatTime(closeTime)),
              ),
            ),
          ] else
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Closed'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Hours',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _days.map((day) => _buildDayRow(day)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
