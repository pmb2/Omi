import 'dart:async';

import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/services/devices.dart';
import 'package:omi/services/services.dart';
import 'package:omi/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

const Duration _wakeCooldown = Duration(seconds: 2);
const Duration _wakeSilenceTimeout = Duration(milliseconds: 1200);
const Duration _wakeBlinkInterval = Duration(milliseconds: 400);
DateTime? _lastWakeOpenedAt;
DateTime? _lastWakeActivityAt;
Timer? _wakeSilenceTimer;
Timer? _wakeBlinkTimer;
bool _wakeActive = false;
bool _wakeBlinkOn = false;
int? _wakeOriginalLedRatio;
int? _cachedFeatures;

Future<void> maybeOpenAgentZeroOnWake(List<TranscriptSegment> segments) async {
  await _updateWakeActivity(segments);

  final url = SharedPreferencesUtil().omiOpenUrl.trim();
  if (url.isEmpty) return;

  final phrases = SharedPreferencesUtil().omiWakePhrases;
  if (phrases.isEmpty) return;

  final now = DateTime.now();
  if (_lastWakeOpenedAt != null && now.difference(_lastWakeOpenedAt!) < _wakeCooldown) return;

  for (final segment in segments) {
    if (!segment.isUser) continue;
    if (_containsWakePhrase(segment.text, phrases)) {
      _lastWakeOpenedAt = now;
      await _startWakeSession();
      await _openExternalUrl(url);
      break;
    }
  }
}

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (!await canLaunchUrl(uri)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool _containsWakePhrase(String text, List<String> phrases) {
  final normalizedText = _normalize(text);
  if (normalizedText.isEmpty) return false;
  final paddedText = ' $normalizedText ';
  for (final phrase in phrases) {
    final normalizedPhrase = _normalize(phrase);
    if (normalizedPhrase.isEmpty) continue;
    if (paddedText.contains(' $normalizedPhrase ')) return true;
  }
  return false;
}

String _normalize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\\s]'), ' ')
      .replaceAll(RegExp(r'\\s+'), ' ')
      .trim();
}

Future<void> _updateWakeActivity(List<TranscriptSegment> segments) async {
  if (!_wakeActive) return;

  final hasUserSpeech = segments.any((segment) => segment.isUser && segment.text.trim().isNotEmpty);
  if (!hasUserSpeech) return;

  _lastWakeActivityAt = DateTime.now();
  _scheduleWakeSilenceTimer();
  _ensureWakeBlinking();
}

Future<void> _startWakeSession() async {
  _wakeActive = true;
  _lastWakeActivityAt = DateTime.now();
  await _triggerWakeFeedback();
  _scheduleWakeSilenceTimer();
}

void _scheduleWakeSilenceTimer() {
  _wakeSilenceTimer?.cancel();
  _wakeSilenceTimer = Timer(_wakeSilenceTimeout, () async {
    if (!_wakeActive) return;
    final lastActivity = _lastWakeActivityAt ?? DateTime.now();
    if (DateTime.now().difference(lastActivity) < _wakeSilenceTimeout) return;
    await _triggerSendFeedback();
    await _stopWakeFeedback();
    _wakeActive = false;
  });
}

Future<void> _triggerWakeFeedback() async {
  try {
    final connection = await _ensureWakeConnection();
    if (connection == null) return;

    final features = await _getFeatures(connection);
    if (_supportsFeature(features, OmiFeatures.haptic)) {
      await connection.performPlayToSpeakerHaptic(2);
    }

    if (_supportsFeature(features, OmiFeatures.ledOverride)) {
      await connection.setLedOverride(2);
    } else if (_supportsFeature(features, OmiFeatures.ledDimming)) {
      _wakeOriginalLedRatio ??= await connection.getLedDimRatio();
      await connection.setLedDimRatio(100);
      _ensureWakeBlinking();
    }
  } catch (e) {
    Logger.debug('Wake feedback error: $e');
  }
}

Future<void> _triggerSendFeedback() async {
  try {
    final connection = await _ensureWakeConnection();
    if (connection == null) return;

    final features = await _getFeatures(connection);
    if (_supportsFeature(features, OmiFeatures.haptic)) {
      await connection.performPlayToSpeakerHaptic(1);
    }
  } catch (e) {
    Logger.debug('Send feedback error: $e');
  }
}

Future<void> _stopWakeFeedback() async {
  _wakeBlinkTimer?.cancel();
  _wakeBlinkTimer = null;
  _wakeBlinkOn = false;

  try {
    final connection = await _ensureWakeConnection();
    if (connection == null) return;

    final features = await _getFeatures(connection);
    if (_supportsFeature(features, OmiFeatures.ledOverride)) {
      await connection.setLedOverride(0);
    } else if (_supportsFeature(features, OmiFeatures.ledDimming)) {
      final ratio = _wakeOriginalLedRatio ?? 30;
      await connection.setLedDimRatio(ratio.clamp(0, 100));
    }
  } catch (e) {
    Logger.debug('Stop wake feedback error: $e');
  } finally {
    _wakeOriginalLedRatio = null;
  }
}

void _ensureWakeBlinking() {
  if (_wakeBlinkTimer != null) return;
  _wakeBlinkTimer = Timer.periodic(_wakeBlinkInterval, (_) async {
    if (!_wakeActive) {
      _wakeBlinkTimer?.cancel();
      _wakeBlinkTimer = null;
      return;
    }
    final connection = await _ensureWakeConnection();
    if (connection == null) return;

    final features = await _getFeatures(connection);
    if (_supportsFeature(features, OmiFeatures.ledOverride)) return;
    if (!_supportsFeature(features, OmiFeatures.ledDimming)) return;

    final fallbackRatio = _wakeOriginalLedRatio ?? 30;
    _wakeBlinkOn = !_wakeBlinkOn;
    final ratio = _wakeBlinkOn ? 100 : fallbackRatio;
    await connection.setLedDimRatio(ratio.clamp(0, 100));
  });
}

Future<dynamic> _ensureWakeConnection() async {
  final deviceId = SharedPreferencesUtil().btDevice.id;
  if (deviceId.isEmpty) return null;
  return ServiceManager.instance().device.ensureConnection(deviceId);
}

Future<int> _getFeatures(dynamic connection) async {
  if (_cachedFeatures != null) return _cachedFeatures!;
  final features = await connection.getFeatures();
  _cachedFeatures = features;
  return features;
}

bool _supportsFeature(int features, int flag) {
  return (features & flag) == flag;
}

