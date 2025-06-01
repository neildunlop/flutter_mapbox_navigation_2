import 'dart:io';
import 'package:coverage/coverage.dart';

void main() async {
  final collector = Collector();
  final hitmap = await collector.collectCoverage();
  final formatter = LcovFormatter();
  final report = formatter.format(hitmap);
  File('coverage/lcov.info').writeAsStringSync(report);
  print('Coverage report generated at coverage/lcov.info');
} 