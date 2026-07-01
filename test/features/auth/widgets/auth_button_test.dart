import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auth/features/auth/widgets/auth_button.dart';

void main() {
  group('AuthButton', () {
    testWidgets('shows label text when not loading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AuthButton(label: 'Sign In', onPressed: () {})),
      ));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator when isLoading is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthButton(label: 'Sign In', onPressed: () {}, isLoading: true),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('button onPressed is null when isLoading is true', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthButton(label: 'Sign In', onPressed: () {}, isLoading: true),
        ),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('button onPressed is null when passed null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AuthButton(label: 'Sign In', onPressed: null)),
      ));
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
