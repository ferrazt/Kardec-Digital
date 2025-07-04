import 'package:flutter_test/flutter_test.dart';
import 'package:kardec_digital/main.dart'; // Ajuste o caminho conforme necessário

void main() {
  testWidgets('Teste básico do app', (WidgetTester tester) async {
    await tester.pumpWidget(const KardecDigitalApp()); // Substitua MyApp por KardecDigitalApp
    // Adicione seus testes aqui
  });
}