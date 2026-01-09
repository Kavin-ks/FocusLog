// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focuslog/main.dart';

void main() {
  testWidgets('Landing page shows app title and primary actions', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the landing page title and primary action buttons are present.
    expect(find.text('Focuslog'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
