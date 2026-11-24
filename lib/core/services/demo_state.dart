import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<DemoLocale, Locale?>(DemoLocale.new);

class DemoLocale extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void select(Locale locale) => state = locale;
}

enum InvitationStatus { idle, pending, incoming, connected, declined }

typedef DemoSession = ({
  String name,
  String email,
  String workspace,
  String partnerEmail,
  InvitationStatus invitation,
});

final demoSessionProvider =
    NotifierProvider<DemoSessionController, DemoSession>(
      DemoSessionController.new,
    );

class DemoSessionController extends Notifier<DemoSession> {
  @override
  DemoSession build() => (
    name: '',
    email: '',
    workspace: '',
    partnerEmail: '',
    invitation: InvitationStatus.idle,
  );

  void signIn(String name, String email) {
    final address = email.trim();
    final displayName = name.trim().isEmpty
        ? address.split('@').first
        : name.trim();
    state = (
      name: displayName,
      email: address,
      workspace: '',
      partnerEmail: '',
      invitation: InvitationStatus.idle,
    );
  }

  void updateProfile(String name, String email) {
    state = (
      name: name,
      email: email,
      workspace: state.workspace,
      partnerEmail: state.partnerEmail,
      invitation: state.invitation,
    );
  }

  void createWorkspace(String name) {
    state = (
      name: state.name,
      email: state.email,
      workspace: name,
      partnerEmail: state.partnerEmail,
      invitation: state.invitation,
    );
  }

  void invite(String email) => _update(InvitationStatus.pending, email);
  void previewIncoming() =>
      _update(InvitationStatus.incoming, state.partnerEmail);
  void accept() => _update(InvitationStatus.connected, state.partnerEmail);
  void decline() => _update(InvitationStatus.declined, state.partnerEmail);
  void signOut() => state = build();

  void _update(InvitationStatus status, String email) {
    state = (
      name: state.name,
      email: state.email,
      workspace: state.workspace,
      partnerEmail: email,
      invitation: status,
    );
  }
}

final profilePhotoProvider = NotifierProvider<DemoPhoto, bool>(DemoPhoto.new);

class DemoPhoto extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

class DemoRecords<T> extends Notifier<List<T>> {
  DemoRecords(this._seed);
  final List<T> Function() _seed;

  @override
  List<T> build() => List.unmodifiable(_seed());

  void save(T entry, {int? index}) {
    final records = [...state];
    if (index == null) {
      records.add(entry);
    } else {
      records[index] = entry;
    }
    state = List.unmodifiable(records);
  }

  void remove(int index) =>
      state = List.unmodifiable([...state]..removeAt(index));
}
