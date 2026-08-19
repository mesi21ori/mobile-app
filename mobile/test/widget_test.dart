import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senbet_app/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const SenbetApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
