/// Central route table — every navigation goes through these helpers.
class RouteNames {
  RouteNames._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const profile = '/profile';

  static String personRoom(String id) => '/room/person/$id';
  static String circleRoom(String id) => '/room/circle/$id';

  /// A room opened from the shelf, landing on one specific kept card.
  static String roomAtCard(String kind, String id, String cardId) =>
      '/room/$kind/$id?card=$cardId';
  static String shelf(String kind, String id) => '/shelf/$kind/$id';
}
