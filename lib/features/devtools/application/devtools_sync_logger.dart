import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/devtools_sync_event.dart';

class DevToolsSyncLogger {
  DevToolsSyncLogger._();

  static final DevToolsSyncLogger instance = DevToolsSyncLogger._();

  static const _prefEvents = 'devtools_sync_events';
  static const _maxEvents = 20;

  Future<void> record(DevToolsSyncEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefEvents) ?? [];
      raw.add(jsonEncode(event.toJson()));
      if (raw.length > _maxEvents) {
        raw.removeRange(0, raw.length - _maxEvents);
      }
      await prefs.setStringList(_prefEvents, raw);
    } catch (_) {
      // best-effort — never let logging crash production sync
    }
  }

  Future<List<DevToolsSyncEvent>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefEvents) ?? [];
      final events = <DevToolsSyncEvent>[];
      for (final s in raw.reversed) {
        try {
          events.add(DevToolsSyncEvent.fromJson(
              jsonDecode(s) as Map<String, dynamic>));
        } catch (_) {
          // skip malformed entries
        }
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefEvents);
    } catch (_) {}
  }
}
