// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'shortlist_service.dart';

class WebShortlistService implements ShortlistService {
  static const _storageKey = 'invision_shortlist_ids';

  @override
  Future<Set<int>> load() async {
    final raw = html.window.localStorage[_storageKey];
    if (raw == null || raw.trim().isEmpty) {
      return <int>{};
    }

    return raw
        .split(',')
        .map((item) => int.tryParse(item.trim()))
        .whereType<int>()
        .toSet();
  }

  @override
  Future<void> save(Set<int> ids) async {
    html.window.localStorage[_storageKey] = ids.join(',');
  }
}

ShortlistService createShortlistServiceImpl() => WebShortlistService();
