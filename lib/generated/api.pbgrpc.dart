// This is a generated file - do not edit.
//
// Generated from api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'api.pb.dart' as $0;

export 'api.pb.dart';

@$pb.GrpcServiceName('api.Metrics')
class MetricsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  MetricsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseStream<$0.UserMetric> getStats(
    $0.Empty request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$getStats, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$getStats = $grpc.ClientMethod<$0.Empty, $0.UserMetric>(
      '/api.Metrics/GetStats',
      ($0.Empty value) => value.writeToBuffer(),
      $0.UserMetric.fromBuffer);
}

@$pb.GrpcServiceName('api.Metrics')
abstract class MetricsServiceBase extends $grpc.Service {
  $core.String get $name => 'api.Metrics';

  MetricsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.UserMetric>(
        'GetStats',
        getStats_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.UserMetric value) => value.writeToBuffer()));
  }

  $async.Stream<$0.UserMetric> getStats_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async* {
    yield* getStats($call, await $request);
  }

  $async.Stream<$0.UserMetric> getStats(
      $grpc.ServiceCall call, $0.Empty request);
}
