import 'package:cloud_firestore/cloud_firestore.dart';

const defaultWorkspaceCurrency = 'LKR';
const workspaceCurrencies = ['LKR', 'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR'];
const maxWorkspaceNameLength = 60;

String? normalizeWorkspaceName(String value) {
  final name = value.trim();
  return name.isEmpty ||
          name.length > maxWorkspaceNameLength ||
          RegExp(r'[\r\n]').hasMatch(name)
      ? null
      : name;
}

class CoupleWorkspace {
  CoupleWorkspace({
    required this.id,
    required this.name,
    required this.createdBy,
    required List<String> memberIds,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  }) : memberIds = List.unmodifiable(memberIds);

  factory CoupleWorkspace.fromDocument(String id, Map<String, dynamic> data) {
    final name = data['name'];
    final owner = data['createdBy'];
    final members = data['memberIds'];
    final currency = data['currency'];
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    if (name is! String ||
        normalizeWorkspaceName(name) == null ||
        owner is! String ||
        owner.isEmpty ||
        members is! List ||
        members.isEmpty ||
        members.length > 2 ||
        members.any((member) => member is! String || member.isEmpty) ||
        members.toSet().length != members.length ||
        !members.contains(owner) ||
        currency is! String ||
        !workspaceCurrencies.contains(currency) ||
        created is! Timestamp ||
        updated is! Timestamp) {
      throw const FormatException('Invalid couple workspace');
    }
    return CoupleWorkspace(
      id: id,
      name: name,
      createdBy: owner,
      memberIds: members.cast<String>(),
      currency: currency,
      createdAt: created.toDate(),
      updatedAt: updated.toDate(),
    );
  }

  final String id;
  final String name;
  final String createdBy;
  final List<String> memberIds;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get memberCount => memberIds.length;
  bool get isFull => memberCount >= 2;
  bool get hasPartner => memberCount == 2;
  bool isCreator(String uid) => createdBy == uid;
  bool hasMember(String uid) => memberIds.contains(uid);

  Map<String, dynamic> toDocument() => {
    'name': name,
    'createdBy': createdBy,
    'memberIds': memberIds,
    'currency': currency,
    'createdAt': createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(updatedAt!),
  };

  CoupleWorkspace copyWith({String? name, String? currency}) => CoupleWorkspace(
    id: id,
    name: name ?? this.name,
    createdBy: createdBy,
    memberIds: memberIds,
    currency: currency ?? this.currency,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
