import 'package:cloud_firestore/cloud_firestore.dart';

import '../../authentication/application/auth_repository.dart';
import '../../profile/data/user_profile.dart';
import 'couple_workspace.dart';

abstract interface class CoupleWorkspaceRepository {
  Future<String> createWorkspace(
    AuthSession user,
    String name,
    String currency,
  );
  Future<CoupleWorkspace?> getWorkspace(String id, String uid);
  Stream<CoupleWorkspace?> watchWorkspace(String id, String uid);
  Future<void> updateSettings(
    CoupleWorkspace workspace,
    String uid,
    String name,
    String currency,
  );
}

class FirestoreCoupleWorkspaceRepository implements CoupleWorkspaceRepository {
  FirestoreCoupleWorkspaceRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _couples =>
      _firestore.collection('couples');

  String _validatedName(String name, String currency) {
    final normalized = normalizeWorkspaceName(name);
    if (normalized == null || !workspaceCurrencies.contains(currency)) {
      throw ArgumentError('Invalid workspace name or currency');
    }
    return normalized;
  }

  @override
  Future<String> createWorkspace(
    AuthSession user,
    String name,
    String currency,
  ) async {
    if (!user.verified) throw StateError('Verified account required');
    final normalized = _validatedName(name, currency);
    final profileRef = _firestore.collection('users').doc(user.uid);
    final workspaceRef = _couples.doc();
    try {
      final id = await _firestore.runTransaction<String?>((transaction) async {
        final snapshot = await transaction.get(profileRef);
        final data = snapshot.data();
        if (data == null) return null;
        final profile = UserProfile.fromDocument(snapshot.id, data);
        if (profile.coupleId case final existing?) return existing;
        final workspace = CoupleWorkspace(
          id: workspaceRef.id,
          name: normalized,
          createdBy: user.uid,
          memberIds: [user.uid],
          currency: currency,
        );
        transaction.set(workspaceRef, workspace.toDocument());
        transaction.update(profileRef, {
          'coupleId': workspace.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return workspace.id;
      });
      if (id == null) throw StateError('User profile does not exist');
      return id;
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
      // Some clients report the rules rejection before retrying a stale
      // transaction. Recover only if a server read confirms a committed link.
      final current = await profileRef.get(
        const GetOptions(source: Source.server),
      );
      final data = current.data();
      if (data != null) {
        final profile = UserProfile.fromDocument(current.id, data);
        if (profile.coupleId case final existing?) return existing;
      }
      rethrow;
    }
  }

  CoupleWorkspace? _decode(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String uid,
  ) {
    final data = snapshot.data();
    if (data == null) return null;
    final workspace = CoupleWorkspace.fromDocument(snapshot.id, data);
    if (!workspace.hasMember(uid)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    return workspace;
  }

  @override
  Future<CoupleWorkspace?> getWorkspace(String id, String uid) async => _decode(
    await _couples.doc(id).get(const GetOptions(source: Source.server)),
    uid,
  );

  @override
  Stream<CoupleWorkspace?> watchWorkspace(String id, String uid) => _couples
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .where(
        (snapshot) =>
            !snapshot.metadata.isFromCache &&
            !snapshot.metadata.hasPendingWrites,
      )
      .map((snapshot) => _decode(snapshot, uid));

  @override
  Future<void> updateSettings(
    CoupleWorkspace workspace,
    String uid,
    String name,
    String currency,
  ) async {
    if (!workspace.isCreator(uid) || !workspace.hasMember(uid)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    }
    final normalized = _validatedName(name, currency);
    if (workspace.name == normalized && workspace.currency == currency) return;
    final reference = _couples.doc(workspace.id);
    await _firestore.runTransaction((transaction) async {
      final current = _decode(await transaction.get(reference), uid);
      if (current == null) throw StateError('Workspace is missing');
      transaction.update(reference, {
        if (workspace.name != normalized) 'name': normalized,
        if (workspace.currency != currency) 'currency': currency,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
