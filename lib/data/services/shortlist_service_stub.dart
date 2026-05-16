import 'shortlist_service.dart';

class MemoryShortlistService implements ShortlistService {
  final Set<int> _ids = <int>{};

  @override
  Future<Set<int>> load() async => {..._ids};

  @override
  Future<void> save(Set<int> ids) async {
    _ids
      ..clear()
      ..addAll(ids);
  }
}

ShortlistService createShortlistServiceImpl() => MemoryShortlistService();
