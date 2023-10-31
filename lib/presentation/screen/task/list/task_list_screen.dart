import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configuration/app_keys.dart';
import '../../../../configuration/routes.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n.dart';
import 'bloc/task_list_bloc.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen() : super(key: ApplicationKeys.taskListScreen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      title: Text(S.of(context).tasksScreenTitle),
      actions: [
        IconButton(
          icon: Icon(Icons.add),
          // onTap: () => Navigator.pushNamed(context, ApplicationRoutes.tasks),
          onPressed: () {
            Navigator.pushNamed(context, ApplicationRoutes.taskNew);
          },
        ),
      ],
    );
  }

  _buildBody(BuildContext context) {
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        switch (state.status) {
          case TaskListStatus.failure:
            return const Center(child: Text('failed to fetch tasks'));
          case TaskListStatus.success:
            if (state.tasks.isEmpty) {
              return const Center(child: Text('no tasks'));
            }
            return ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                return index >= state.tasks.length
                    ? const Center(child: CircularProgressIndicator())
                    : TaskListItem(task: state.tasks[index]);
              },
            );
          case TaskListStatus.initial:
            log("TaskListStatus.initial");
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class TaskListItem extends StatelessWidget {
  const TaskListItem({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      child: ListTile(
        leading: Text(
          '${task.id}',
          style: textTheme.caption,
        ),
        title: task.name != null
            ? Text(
                '${task.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        subtitle: Text(
          '${task.price}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
