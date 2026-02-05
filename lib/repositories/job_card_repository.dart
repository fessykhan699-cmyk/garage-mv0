import '../models/job_card.dart';

abstract class JobCardRepository {
  Future<JobCard> create(JobCard jobCard);
  Future<JobCard?> fetch(String id);
  Future<List<JobCard>> listByGarage(String garageId);
  Stream<List<JobCard>> watchByGarage(String garageId);
  Future<void> update(JobCard jobCard);
  Future<void> delete(String id);
}
