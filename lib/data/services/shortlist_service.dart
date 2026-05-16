import 'shortlist_service_stub.dart'
    if (dart.library.html) 'shortlist_service_web.dart';

abstract class ShortlistService {
  Future<Set<int>> load();

  Future<void> save(Set<int> ids);
}

ShortlistService createShortlistService() => createShortlistServiceImpl();
