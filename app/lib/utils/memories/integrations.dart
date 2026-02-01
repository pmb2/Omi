import 'package:omi/backend/http/webhooks.dart';
import 'package:omi/backend/schema/message.dart';
import 'package:omi/backend/schema/transcript_segment.dart';
import 'package:omi/services/sockets/composite_socket_health.dart';
import 'package:omi/utils/logger.dart';
import 'package:omi/utils/omi/wake.dart';

triggerTranscriptSegmentReceivedEvents(
  List<TranscriptSegment> segments,
  String sessionId, {
  Function(ServerMessage)? sendMessageToChat,
}) async {
  await maybeOpenAgentZeroOnWake(segments);
  final secondaryAvailable = CompositeSocketHealth.instance.secondaryAvailable;
  webhookOnTranscriptReceivedCall(
    segments,
    sessionId,
    fallbackToOmiBackend: !secondaryAvailable,
    forwardToOmiBackend: true,
  ).then((s) {
    if (s.isNotEmpty) Logger.debug('webhookOnTranscriptReceived response: $s');
  });
  // TODO: restore me, how to trigger from backend
}
