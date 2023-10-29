import 'package:dart_json_mapper/dart_json_mapper.dart';

import '../http_utils.dart';
import '../models/task.dart';

/// task repository
///
/// This class is responsible for all the task related operations
/// list, create, update, delete etc.
class TaskRepository {
  /// Retrieve all tasks method that retrieves all the tasks
  Future<List<Task>> getTasks() async {
    final tasksRequest = await HttpUtils.getRequest("/tasks");
    return JsonMapper.deserialize<List<Task>>(tasksRequest.body)!;
  }

  /// Retrieve task method that retrieves a task by id
  ///
  /// @param id the task id
  Future<Task> getTask(String id) async {
    final taskRequest = await HttpUtils.getRequest("/tasks/$id");
    return JsonMapper.deserialize<Task>(taskRequest.body)!;
  }

  /// Create task method that creates a new task
  ///
  /// @param task the task object
  Future<String?> createTask(Task task) async {
    final saveRequest = await HttpUtils.postRequest<Task>("/tasks", task);
    String? result;
    if (saveRequest.statusCode != 200) {
      if (saveRequest.headers[HttpUtils.errorHeader] != null) {
        result = saveRequest.headers[HttpUtils.errorHeader];
      } else {
        result = HttpUtils.errorServerKey;
      }
    } else {
      result = HttpUtils.successResult;
    }

    return result;
  }

  /// Update task method that updates a task
  ///
  /// @param task the task object
  updateTask(Task task, String id) {
    return HttpUtils.putRequest<Task>("/tasks/$id", task);
  }

  /// Delete task method that deletes a task
  ///
  /// @param id the task id
  deleteTask(String id) {
    return HttpUtils.deleteRequest("/tasks/$id");
  }
}