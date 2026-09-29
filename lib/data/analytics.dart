import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Usage events (supabase/app_events.sql): which screens and features are
/// used, never health data. Events are queued and sent in batches; sending
/// never blocks or breaks the app, and nothing is sent when [enabled] is
/// false (Settings -> share usage data).
abstract class EventSink {
  Future<void> send(List<Map<String, Object?>> rows);
}

class SupabaseEventSink implements EventSink {
  final SupabaseClient client;
  SupabaseEventSink(this.client);

  @override
  Future<void> send(List<Map<String, Object?>> rows) =>
      client.from('app_events').insert(rows);
}

class Analytics {
  final EventSink? sink;
  final Future<String> Function() _deviceId;
  final String sessionId = _randomId();
  final String platform;
  final String appVersion;
  final Duration flushDelay;
  static const _maxQueue = 500;

  var enabled = true;
  final _queue = <Map<String, Object?>>[];
  Timer? _timer;
  var _sending = false;

  Analytics({
    this.sink,
    Future<String> Function()? deviceId,
    this.appVersion = const String.fromEnvironment(
      'APP_VERSION',
      defaultValue: '1.0.0',
    ),
    this.flushDelay = const Duration(seconds: 20),
  }) : _deviceId = deviceId ?? _prefsDeviceId,
       platform = kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Queued events not yet sent (for tests).
  List<Map<String, Object?>> get pending => List.unmodifiable(_queue);

  /// Records an event. [props] must not contain health data.
  void log(String name, [Map<String, Object?> props = const {}]) {
    if (!enabled || sink == null) return;
    if (_queue.length >= _maxQueue) _queue.removeAt(0);
    _queue.add({
      'client_at': DateTime.now().toUtc().toIso8601String(),
      'session_id': sessionId,
      'name': name,
      'props': props,
      'platform': platform,
      'app_version': appVersion,
    });
    _timer ??= Timer(flushDelay, flush);
  }

  /// Sends queued events now (also called when the app goes to background).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final s = sink;
    if (s == null || _sending || _queue.isEmpty) return;
    if (!enabled) {
      _queue.clear();
      return;
    }
    _sending = true;
    final batch = List.of(_queue);
    try {
      final device = await _deviceId();
      await s.send([
        for (final e in batch) {...e, 'device_id': device},
      ]);
      _queue.removeRange(0, math.min(batch.length, _queue.length));
    } catch (e) {
      debugPrint('analytics flush failed: $e'); // retried on the next flush
    } finally {
      _sending = false;
    }
  }

  void setEnabled(bool on) {
    enabled = on;
    if (!on) {
      _timer?.cancel();
      _timer = null;
      _queue.clear();
    }
  }

  static Future<String> _prefsDeviceId() async {
    const key = 'adapt.v1.deviceId';
    final prefs = SharedPreferencesAsync();
    try {
      final id = await prefs.getString(key);
      if (id != null) return id;
      final fresh = _randomId();
      await prefs.setString(key, fresh);
      return fresh;
    } catch (_) {
      return _session;
    }
  }

  static final _session = _randomId();

  static String _randomId() {
    final r = math.Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
