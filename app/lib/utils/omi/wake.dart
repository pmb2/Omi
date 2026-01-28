import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:url_launcher/url_launcher.dart';

const Duration _wakeCooldown = Duration(seconds: 2);
DateTime? _lastWakeOpenedAt;

Future<void> maybeOpenAgentZeroOnWake(List<TranscriptSegment> segments) async {
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

