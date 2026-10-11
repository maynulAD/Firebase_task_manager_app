import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});
  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  final _search = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(TaskItem task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteTask(task.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red;
      case 'Low': return Colors.green;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Test local notification',
            onPressed: () => NotificationService.instance.showLocalNotification(
              title: 'New Task',
              body: 'You have a task to complete.',
            ),
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => AuthService().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?.displayName?.split(' ').first ?? user?.email?.split('@').first ?? 'there'} 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Let’s make today productive.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tasks'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'All', label: Text('All')),
                    ButtonSegment(value: 'Pending', label: Text('Pending')),
                    ButtonSegment(value: 'Completed', label: Text('Completed')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) => setState(() => _filter = selection.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskItem>>(
              stream: _service.watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load tasks.\n${snapshot.error}', textAlign: TextAlign.center),
                ));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final query = _search.text.trim().toLowerCase();
                final tasks = snapshot.data!.where((task) {
                  final filterMatch = _filter == 'All' ||
                    (_filter == 'Completed' && task.isCompleted) ||
                    (_filter == 'Pending' && !task.isCompleted);
                  return filterMatch && (task.title.toLowerCase().contains(query) ||
                    task.description.toLowerCase().contains(query));
                }).toList();
                if (tasks.isEmpty) return const Center(child: Text('No tasks found. Add your first task!'));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) => _service.setCompleted(task, value ?? false),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(task: task),
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task.title, style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      )),
                                      if (task.description.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.black54)),
                                      ],
                                      const SizedBox(height: 10),
                                      Wrap(spacing: 8, runSpacing: 6, children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _priorityColor(task.priority).withOpacity(.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(task.priority, style: TextStyle(
                                            color: _priorityColor(task.priority), fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                        Chip(
                                          avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                                          label: Text(DateFormat('d MMM').format(task.dueDate)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => TaskFormScreen(task: task),
                                ));
                                if (value == 'delete') _delete(task);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
