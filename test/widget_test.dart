// Basic widget test for CampusHub
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_timetable_builder/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusHubApp());
    expect(find.text('CampusHub'), findsAny);
  });
}
