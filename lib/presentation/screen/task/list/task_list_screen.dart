import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/task_list_bloc.dart';
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<TaskListBloc>().add(LoadMoreTasks());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          if (state.status == TaskListStatus.failure) {
            log("task boş");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          log("task builder --");
          return ListView.builder(
            itemCount: state.tasks.length + 1,
            itemBuilder: (context, index) {
              if (index < state.tasks.length) {
                return ListTile(
                  title: Text(state.tasks[index].name!),
                );
              } else if (index == state.tasks.length) {
                context.read<TaskListBloc>().add(LoadMoreTasks());
              }
              return Container();
            },
          );
        },
      ),
    );
  }
}
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: _buildBody(context),
//     );
//   }
//
//   _buildAppBar(BuildContext context) {
//     return AppBar(
//       toolbarHeight: 80,
//       title: Text(S.of(context).tasksScreenTitle),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.add),
//           onPressed: () {
//             Navigator.pushNamed(context, ApplicationRoutes.taskNew);
//           },
//         ),
//       ],
//     );
//   }
//
//   _buildBody(BuildContext context) {
//     return BlocBuilder<TaskListBloc, TaskListState>(
//       builder: (context, state) {
//         switch (state.status) {
//           case TaskListStatus.failure:
//             return const Center(child: Text('failed to fetch tasks'));
//           case TaskListStatus.success:
//             if (state.tasks.isEmpty) {
//               return const Center(child: Text('no tasks'));
//             }
//             return ListView.builder(
//               itemBuilder: (BuildContext context, int index) {
//                 return index >= state.tasks.length
//                     ? const BottomLoader()
//                     : TaskListItemWidget(task: state.tasks[index]);
//               },
//               itemCount: state.hasReachedMax
//                   ? state.tasks.length
//                   : state.tasks.length + 1,
//               controller: _scrollController,
//             );
//           case TaskListStatus.initial:
//             return const Center(child: CircularProgressIndicator());
//         }
//       },
//     );
//   }
//
//
//   // TODO: implement onScroll with infinite scroll
//   void _onScroll() {
//     if (_isBottom) context.read<TaskListBloc>().add(TaskListLoad());
//   }
//
//   // TODO: implement _isBottom with infinite scroll
//   bool get _isBottom {
//     if (!_scrollController.hasClients) return false;
//     final maxScroll = _scrollController.position.maxScrollExtent;
//     final currentScroll = _scrollController.offset;
//     return currentScroll >= (maxScroll * 0.9);
//   }
// }

// class BottomLoader extends StatelessWidget {
//   const BottomLoader({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: SizedBox(
//         height: 24,
//         width: 24,
//         child: CircularProgressIndicator(strokeWidth: 1.5),
//       ),
//     );
//   }
// }
