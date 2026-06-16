import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/debt.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channel = MethodChannel('masarifi/notifications');

  static const _taskChannelId = 'masarifi_tasks';
  static const _debtChannelId = 'masarifi_debts';

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    _initialized = defaultTargetPlatform == TargetPlatform.android;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) return false;
    try {
      await _channel.invokeMethod<bool>('requestPermissions');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> rescheduleAll({
    required List<TaskItem> tasks,
    required List<Debt> debts,
  }) async {
    if (!_initialized) return;

    await _channel.invokeMethod<void>('cancelAll');

    for (final task in tasks) {
      await _scheduleTask(task);
    }
    for (final debt in debts) {
      await _scheduleDebt(debt);
    }
  }

  Future<void> _scheduleTask(TaskItem task) async {
    if (_isTaskInactive(task)) return;

    final schedules = _taskSchedules(task);
    for (final entry in schedules.entries) {
      await _scheduleNative(
        id: entry.key,
        channelId: _taskChannelId,
        title: entry.value.title,
        body: entry.value.body,
        when: entry.value.when,
      );
    }
  }

  Future<void> _scheduleDebt(Debt debt) async {
    if (!debt.reminderEnabled || debt.status == DebtStatus.paid) return;

    final dueMorning = DateTime(
      debt.dueDate.year,
      debt.dueDate.month,
      debt.dueDate.day,
      9,
    );

    final reminders = <int, _Schedule>{
      0: _Schedule(
        when: dueMorning.subtract(const Duration(days: 3)),
        title: 'تذكير بدين',
        body: 'دين ${debt.personName} يستحق خلال 3 أيام',
      ),
      1: _Schedule(
        when: dueMorning.subtract(const Duration(days: 1)),
        title: 'تذكير بدين',
        body: 'دين ${debt.personName} يستحق غداً',
      ),
      2: _Schedule(
        when: dueMorning,
        title: 'استحقاق دين اليوم',
        body: 'دين ${debt.personName} يستحق اليوم',
      ),
    };

    final baseId = _baseId(debt.id, offset: 2000000);
    for (final entry in reminders.entries) {
      await _scheduleNative(
        id: baseId + entry.key,
        channelId: _debtChannelId,
        title: entry.value.title,
        body: entry.value.body,
        when: entry.value.when,
      );
    }
  }

  Map<int, _Schedule> _taskSchedules(TaskItem task) {
    final result = <int, _Schedule>{};
    final baseId = _baseId(task.id);

    final dueTimes = _upcomingOccurrences(task);
    if (dueTimes.isEmpty) return result;

    final nextDue = dueTimes.first;
    final kind = task.isAppointment ? 'موعد' : 'مهمة';

    result[baseId] = _Schedule(
      when: nextDue,
      title: '$kind: ${task.title}',
      body: task.isAppointment ? 'حان وقت الموعد' : 'حان وقت إنجاز المهمة',
    );

    if (task.isAppointment && task.alertBefore != null) {
      final alertTime = _subtractAlert(nextDue, task.alertBefore!);
      result[baseId + 1] = _Schedule(
        when: alertTime,
        title: 'تذكير بموعد',
        body: '${task.title} — ${_alertLabel(task.alertBefore!)}',
      );
    } else if (!task.isAppointment) {
      final reminder = nextDue.subtract(const Duration(hours: 1));
      result[baseId + 1] = _Schedule(
        when: reminder,
        title: 'تذكير بمهمة',
        body: '${task.title} — بعد ساعة',
      );
    }

    return result;
  }

  List<DateTime> _upcomingOccurrences(TaskItem task) {
    final now = DateTime.now();
    final dates = <DateTime>[];

    if (task.hasRecurrence) {
      final start = DateTime(now.year, now.month, now.day);
      for (var i = 0; i < 370; i++) {
        final day = start.add(Duration(days: i));
        if (!task.occursOn(day)) continue;
        if (task.lastCompletedDate == TaskItem.dateKey(day)) continue;
        dates.add(task.occurrenceDateTime(day));
      }
    } else if (!task.isCompleted) {
      dates.add(task.dateTime);
    }

    dates.sort();
    return dates.where((d) => d.isAfter(now)).take(1).toList();
  }

  bool _isTaskInactive(TaskItem task) {
    if (task.hasRecurrence) {
      return task.isEffectivelyCompleted && !_hasFutureOccurrence(task);
    }
    return task.isCompleted;
  }

  bool _hasFutureOccurrence(TaskItem task) {
    return _upcomingOccurrences(task).isNotEmpty;
  }

  DateTime _subtractAlert(DateTime occurrence, AlertBefore alert) {
    switch (alert) {
      case AlertBefore.minutes15:
        return occurrence.subtract(const Duration(minutes: 15));
      case AlertBefore.hour1:
        return occurrence.subtract(const Duration(hours: 1));
      case AlertBefore.day1:
        return occurrence.subtract(const Duration(days: 1));
    }
  }

  String _alertLabel(AlertBefore alert) {
    switch (alert) {
      case AlertBefore.minutes15:
        return 'بعد 15 دقيقة';
      case AlertBefore.hour1:
        return 'بعد ساعة';
      case AlertBefore.day1:
        return 'غداً';
    }
  }

  Future<void> _scheduleNative({
    required int id,
    required String channelId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!when.isAfter(DateTime.now())) return;

    try {
      await _channel.invokeMethod<void>('schedule', {
        'id': id,
        'channelId': channelId,
        'title': title,
        'body': body,
        'triggerAt': when.millisecondsSinceEpoch,
      });
    } catch (_) {
      // تجاهل على المنصات غير المدعومة
    }
  }

  int _baseId(String id, {int offset = 0}) {
    return (id.hashCode & 0x3FFFFFFF) + offset;
  }
}

class _Schedule {
  final DateTime when;
  final String title;
  final String body;

  const _Schedule({
    required this.when,
    required this.title,
    required this.body,
  });
}
