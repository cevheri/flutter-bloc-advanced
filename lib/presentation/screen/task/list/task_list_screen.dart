import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configuration/app_keys.dart';
import '../../../../configuration/routes.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n.dart';
import 'bloc/task_list_bloc.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen() : super(key: ApplicationKeys.taskListScreen);

  @override
  State<TaskListScreen> createState() => _TaskListState();
}

class _TaskListState extends State<TaskListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

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
                    ? const BottomLoader()
                    : TaskListItem(task: state.tasks[index]);
              },
              itemCount: state.hasReachedMax
                  ? state.tasks.length
                  : state.tasks.length + 1,
              controller: _scrollController,
            );
          case TaskListStatus.initial:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // TODO: implement dispose with infinite scroll
  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // TODO: implement onScroll with infinite scroll
  void _onScroll() {
    if (_isBottom) context.read<TaskListBloc>().add(TaskListLoad());
  }

  // TODO: implement _isBottom with infinite scroll
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

class TaskListItem extends StatelessWidget {
  const TaskListItem({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      child: ListTile(
        leading: Text(
          '${task.id}',
          style: textTheme.bodySmall,
        ),
        title: task.name != null
            ? Text(
                '${task.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        isThreeLine: true,
        subtitle: Text(
          '${task.price}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        dense: true,
        onTap: () {
          // TODO: implement onTap
          Navigator.pushNamed(context, ApplicationRoutes.tasksDetail, arguments: task.id);
        }
      ),
    );
  }
}

class BottomLoader extends StatelessWidget {
  const BottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
    );
  }
}
