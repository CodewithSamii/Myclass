import '../core/models.dart';
import '../core/repositories.dart';
import 'fixtures.dart';

class MockBusRepository implements BusRepository {
  @override
  Future<List<BusRoute>> routes() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return Fixtures.routes;
  }
}

class MockFacultyRepository implements FacultyRepository {
  @override
  Future<List<FacultyMember>> faculty() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Fixtures.faculty;
  }
}
