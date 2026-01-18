import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'generated/api.pb.dart';

Stream<UserMetric> sseUserMetricStream(String url) {
  final controller = StreamController<UserMetric>();
  final es = EventSource(url);

  es.onMessage.listen((ev) {
    try {
      final data = jsonDecode(ev.data!);
      final m = UserMetric()
        ..userId = data['userId'] ?? ''
        ..userName = data['userName'] ?? ''
        ..heartRate = (data['heartRate'] is int) ? data['heartRate'] : (data['heartRate'] as num).toInt();
      controller.add(m);
    } catch (e, st) {
      controller.addError(e, st);
    }
  });

  es.onError.listen((ev) {
    controller.addError(Exception('EventSource error'));
  });

  controller.onCancel = () {
    es.close();
  };

  return controller.stream;
}
