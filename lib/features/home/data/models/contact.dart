/// A phone contact — invitable to Space when not yet here.
class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.onSpace = false,
  });

  final String id;
  final String name;
  final String phone;
  final bool onSpace;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        onSpace: json['onSpace'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'phone': phone, 'onSpace': onSpace};
}
