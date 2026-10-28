// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simulados_concursos/main.dart';
import 'package:simulados_concursos/providers/app_provider.dart';

void main() {
  testWidgets('carrega a tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const SimuladosApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Simulados de concursos'), findsOneWidget);
  });
}
