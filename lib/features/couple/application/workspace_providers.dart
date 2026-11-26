import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_repository.dart';
import '../../profile/application/profile_providers.dart';
import '../data/couple_workspace.dart';
import '../data/couple_workspace_repository.dart';

final workspaceRepositoryProvider = Provider<CoupleWorkspaceRepository>(
  (ref) => FirestoreCoupleWorkspaceRepository(ref.watch(firestoreProvider)),
);

final currentWorkspaceProvider = StreamProvider.autoDispose<CoupleWorkspace?>((
  ref,
) {
  final key = ref.watch(
    activeProfileProvider.select((value) {
      final profile = value.asData?.value;
      final id = profile?.coupleId;
      return id == null ? null : (uid: profile!.uid, id: id);
    }),
  );
  final user = ref.watch(
    authSessionProvider.select((value) {
      final session = value.asData?.value;
      return session?.verified == true ? session!.uid : null;
    }),
  );
  if (key == null || key.uid != user) {
    return Stream<CoupleWorkspace?>.value(null);
  }
  final output = StreamController<CoupleWorkspace?>();
  final deadline = Timer(const Duration(seconds: 15), () {
    output.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
  });
  final subscription = ref
      .watch(workspaceRepositoryProvider)
      .watchWorkspace(key.id, key.uid)
      .listen(
        (workspace) {
          deadline.cancel();
          output.add(workspace);
        },
        onError: (Object error, StackTrace stack) {
          deadline.cancel();
          output.addError(error, stack);
        },
        onDone: () {
          deadline.cancel();
          unawaited(output.close());
        },
      );
  ref.onDispose(() {
    deadline.cancel();
    unawaited(subscription.cancel());
    unawaited(output.close());
  });
  return output.stream;
}, retry: (_, _) => null);

final workspaceControllerProvider = Provider<WorkspaceController>(
  (ref) => WorkspaceController(ref),
);

class WorkspaceController {
  WorkspaceController(this._ref);
  final Ref _ref;

  AuthSession _requireUser(String uid) {
    final session = _ref.read(authSessionProvider).asData?.value;
    if (session == null || !session.verified || session.uid != uid) {
      throw StateError('Verified session changed');
    }
    return session;
  }

  Future<void> create(String uid, String name, String currency) async {
    await _ref
        .read(workspaceRepositoryProvider)
        .createWorkspace(_requireUser(uid), name, currency);
  }

  Future<void> update(
    String uid,
    CoupleWorkspace workspace,
    String name,
    String currency,
  ) async {
    _requireUser(uid);
    await _ref
        .read(workspaceRepositoryProvider)
        .updateSettings(workspace, uid, name, currency);
  }
}
