import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:omi/backend/http/shared.dart';
import 'package:omi/backend/preferences.dart';
import 'package:omi/backend/schema/conversation.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/utils/logger.dart';

Future<String> webhookOnConversationCreatedCall(ServerConversation? conversation, {bool returnRawBody = false}) async {
  if (conversation == null) return '';
  Logger.debug('devModeWebhookCall: $conversation');
  String url = SharedPreferencesUtil().webhookOnConversationCreated;
  if (url.isEmpty) return '';
  if (url.contains('?')) {
    url += '&uid=${SharedPreferencesUtil().uid}';
  } else {
    url += '?uid=${SharedPreferencesUtil().uid}';
  }
  Logger.debug('triggerConversationRequestAtEndpoint: $url');
  var data = conversation.toJson();
  try {
    var response = await makeApiCall(
      url: url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
      method: 'POST',
    );
    Logger.debug('response: ${response?.statusCode}');
    if (returnRawBody) return jsonEncode({'statusCode': response?.statusCode, 'body': response?.body});
    var body = jsonDecode(response?.body ?? '{}');
    return body['message'] ?? '';
  } on FormatException catch (e) {
    Logger.debug('Response not a valid json: $e');
    return '';
  } catch (e) {
    Logger.debug('Error triggering conversation request at endpoint: $e');
    return '';
  }
}

Future<String> webhookOnTranscriptReceivedCall(List<TranscriptSegment> segments, String sessionId) async {
  if (segments.isEmpty) return '';
  String url = SharedPreferencesUtil().webhookOnTranscriptReceived;
  if (url.isEmpty) return '';
  if (url.contains('?')) {
    url += '&uid=${SharedPreferencesUtil().uid}';
  } else {
    url += '?uid=${SharedPreferencesUtil().uid}';
  }
  Logger.debug('triggerTranscriptRequestAtEndpoint: $url');
  final payload = {
    'session_id': sessionId,
    'segments': segments.map((s) => s.toJson()).toList(),
  };
  try {
    final response = await makeApiCall(
      url: url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
      method: 'POST',
    );
    Logger.debug('response: ${response?.statusCode}');
    final body = jsonDecode(response?.body ?? '{}');
    return body['message'] ?? '';
  } on FormatException catch (e) {
    Logger.debug('Response not a valid json: $e');
    return '';
  } catch (e) {
    Logger.debug('Error triggering transcript request at endpoint: $e');
    return '';
  }
}
