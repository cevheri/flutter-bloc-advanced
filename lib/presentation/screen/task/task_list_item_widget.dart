import 'package:flutter/material.dart';

import '../../../data/models/task.dart';

class TaskListItemWidget extends StatelessWidget {
  const TaskListItemWidget({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      child: ListTile(
          leading: Text('${task.id}', style: textTheme.bodySmall),
          title: task.name != null ? Text('${task.name}', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          isThreeLine: true,
          subtitle: Text('${task.price}', maxLines: 1, overflow: TextOverflow.ellipsis),
          dense: true,
          onTap: () {
            // Navigator.pushNamed(context, ApplicationRoutes.tasksDetail, arguments: task.id);
          }),
    );
  }
}
