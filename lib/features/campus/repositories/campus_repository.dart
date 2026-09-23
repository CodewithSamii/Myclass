import '../../../core/models.dart';

abstract interface class BusRepository {
  Future<List<BusRoute>> routes();
}

abstract interface class FacultyRepository {
  Future<List<FacultyMember>> faculty();
}
