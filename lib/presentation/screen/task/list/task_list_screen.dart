import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_advance/configuration/routes.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../configuration/app_keys.dart';
import '../../../../data/repository/task_repository.dart';
import 'bloc/task_list_bloc.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen() : super(key: ApplicationKeys.taskListScreen);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(
        taskRepository: context.read<TaskRepository>(),
      )..add(const TaskListLoad()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, ApplicationRoutes.account);
              },
            ),
          ],
        ),
        // body: BlocBuilder<TaskListBloc, TaskListState>(
        //   builder: (context, state) {
        //     if (state is TaskListLoading) {
        //       return const Center(
        //         child: CircularProgressIndicator(),
        //       );
        //     } else if (state is TaskListLoaded) {
        //       return ListView.builder(
        //         itemCount: state.tasks.length,
        //         itemBuilder: (context, index) {
        //           final task = state.tasks[index];
        //           return ListTile(
        //             title: Text(task.title),
        //             subtitle: Text(task.description),
        //             trailing: Checkbox(
        //               value: task.isCompleted,
        //               onChanged: (value) {
        //                 context.read<TaskListBloc>().add(
        //                       TaskListUpdate(
        //                         task.copyWith(isCompleted: value),
        //                       ),
        //                     );
        //               },
        //             ),
        //           );
        //         },
        //       );
        //     } else {
        //       return const Center(
        //         child: Text('Something went wrong!'),
        //       );
        //     }
        //   },
        // ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () async {
        //     final result = await Navigator.pushNamed(
        //       context,
        //       Routes.taskForm,
        //       arguments: TaskFormArguments(
        //         task: null,
        //       ),
        //     );
        //     if (result != null) {
        //       context.read<TaskListBloc>().add(
        //             TaskListCreate(result),
        //           );
        //     }
        //   },
        //   child: const Icon(Icons.add),
        // ),
      ),
    );
  }
}
