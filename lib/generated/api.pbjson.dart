// This is a generated file - do not edit.
//
// Generated from api.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

@$core.Deprecated('Use userMetricDescriptor instead')
const UserMetric$json = {
  '1': 'UserMetric',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'user_name', '3': 2, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'heart_rate', '3': 3, '4': 1, '5': 5, '10': 'heartRate'},
  ],
};

/// Descriptor for `UserMetric`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userMetricDescriptor = $convert.base64Decode(
    'CgpVc2VyTWV0cmljEhcKB3VzZXJfaWQYASABKAlSBnVzZXJJZBIbCgl1c2VyX25hbWUYAiABKA'
    'lSCHVzZXJOYW1lEh0KCmhlYXJ0X3JhdGUYAyABKAVSCWhlYXJ0UmF0ZQ==');
