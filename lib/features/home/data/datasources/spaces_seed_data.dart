import '../../../../core/constants/presence.dart';
import '../models/circle_space.dart';
import '../models/contact.dart';
import '../models/person.dart';

/// Seed data mirroring the web prototype — replaced by GET /spaces later.
class SpacesSeedData {
  SpacesSeedData._();

  static DateTime _ago({int minutes = 0, int hours = 0, int days = 0}) =>
      DateTime.now()
          .subtract(Duration(minutes: minutes, hours: hours, days: days));

  static List<Person> people() => [
        Person(id: 'elena', name: 'Elena', paletteId: 'ember', sizeKey: 'xl', unread: 2, presence: Presence.here, x: 42, y: 26, lastActivity: _ago(minutes: 3)),
        Person(id: 'ada', name: 'Ada', paletteId: 'rose', sizeKey: 'sm', presence: Presence.away, x: 84, y: 14, lastActivity: _ago(hours: 9)),
        Person(id: 'julian', name: 'Julian', paletteId: 'tide', sizeKey: 'lg', presence: Presence.recent, x: 20, y: 58, lastActivity: _ago(minutes: 42)),
        Person(id: 'mira', name: 'Mira', paletteId: 'moss', sizeKey: 'md', unread: 1, presence: Presence.away, x: 78, y: 50, lastActivity: _ago(hours: 20)),
        Person(id: 'thomas', name: 'Thomas', paletteId: 'sand', sizeKey: 'sm', presence: Presence.away, x: 50, y: 82, lastActivity: _ago(days: 2)),
        Person(id: 'ines', name: 'Inés', paletteId: 'iris', sizeKey: 'sm', presence: Presence.away, x: 86, y: 84, lastActivity: _ago(days: 4)),
        Person(id: 'noor', name: 'Noor', paletteId: 'rose', sizeKey: 'lg', unread: 3, presence: Presence.here, x: 30, y: 30, lastActivity: _ago(minutes: 1)),
        Person(id: 'kaito', name: 'Kaito', paletteId: 'tide', sizeKey: 'md', presence: Presence.recent, x: 60, y: 40, lastActivity: _ago(hours: 1)),
        Person(id: 'sofia', name: 'Sofia', paletteId: 'ember', sizeKey: 'md', unread: 1, presence: Presence.here, x: 25, y: 70, lastActivity: _ago(minutes: 6)),
        Person(id: 'owen', name: 'Owen', paletteId: 'moss', sizeKey: 'sm', presence: Presence.away, x: 70, y: 70, lastActivity: _ago(days: 1)),
        Person(id: 'amara', name: 'Amara', paletteId: 'iris', sizeKey: 'lg', presence: Presence.recent, x: 40, y: 55, lastActivity: _ago(minutes: 55)),
        Person(id: 'leo', name: 'Leo', paletteId: 'sand', sizeKey: 'md', unread: 2, presence: Presence.away, x: 65, y: 25, lastActivity: _ago(hours: 14)),
        Person(id: 'yuki', name: 'Yuki', paletteId: 'tide', sizeKey: 'sm', presence: Presence.away, x: 15, y: 40, lastActivity: _ago(days: 3)),
        Person(id: 'ravi', name: 'Ravi', paletteId: 'ember', sizeKey: 'md', presence: Presence.recent, x: 55, y: 65, lastActivity: _ago(minutes: 30)),
        Person(id: 'marta', name: 'Marta', paletteId: 'rose', sizeKey: 'sm', unread: 1, presence: Presence.here, x: 90, y: 35, lastActivity: _ago(minutes: 8)),
        Person(id: 'felix', name: 'Felix', paletteId: 'moss', sizeKey: 'sm', presence: Presence.away, x: 10, y: 80, lastActivity: _ago(days: 5)),
        Person(id: 'iris', name: 'Iris', paletteId: 'iris', sizeKey: 'md', presence: Presence.recent, x: 75, y: 90, lastActivity: _ago(hours: 2)),
        Person(id: 'dante', name: 'Dante', paletteId: 'sand', sizeKey: 'lg', unread: 4, presence: Presence.here, x: 35, y: 90, lastActivity: _ago(minutes: 2)),
      ];

  static List<CircleSpace> circles() => [
        CircleSpace(id: 'kyoto-trip', name: 'Kyoto, October', memberIds: const ['elena', 'julian', 'mira'], sizeKey: 'xl', unread: 2, presence: Presence.here, x: 55, y: 56, lastActivity: _ago(minutes: 12)),
        CircleSpace(id: 'book-club', name: 'Slow Reads', memberIds: const ['noor', 'amara', 'sofia', 'yuki'], sizeKey: 'lg', presence: Presence.recent, x: 30, y: 45, lastActivity: _ago(hours: 3)),
        CircleSpace(id: 'sunday-supper', name: 'Sunday Supper', memberIds: const ['leo', 'marta', 'ravi', 'iris', 'owen'], sizeKey: 'lg', unread: 1, presence: Presence.away, x: 70, y: 60, lastActivity: _ago(days: 1)),
      ];

  static List<Contact> contacts() => const [
        Contact(id: 'c-aarav', name: 'Aarav Mehta', phone: '+91 98200 11223'),
        Contact(id: 'c-beatrice', name: 'Beatrice Lange', phone: '+49 171 555 0142'),
        Contact(id: 'c-caleb', name: 'Caleb Rhodes', phone: '+1 415 555 0134'),
        Contact(id: 'c-elena-r', name: 'Elena Russo', phone: '+39 333 555 0177', onSpace: true),
        Contact(id: 'c-grace', name: 'Grace Okafor', phone: '+234 803 555 0190'),
        Contact(id: 'c-hiro', name: 'Hiro Nakamura', phone: '+81 90 5550 1122'),
        Contact(id: 'c-isla', name: 'Isla Cameron', phone: '+44 7700 900123'),
        Contact(id: 'c-karim', name: 'Karim Haddad', phone: '+961 3 555 019'),
        Contact(id: 'c-lina', name: 'Lina Moreno', phone: '+34 612 555 044'),
      ];
}
