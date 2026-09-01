import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('QR Attendance app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const QRAttendanceApp());

    expect(find.text('QR ATTENDANCE'), findsOneWidget);
  });
}
