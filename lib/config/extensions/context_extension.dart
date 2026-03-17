import 'package:flutter/material.dart';

extension BuildContextEx on BuildContext {
  /// MediaQuery.of(this).size への convenience method です
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
}
