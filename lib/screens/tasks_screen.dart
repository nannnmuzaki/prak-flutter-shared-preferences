import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_drawer.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  final _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getStringList('tasks') ?? [];
    setState(() {
      _tasks = taskList.map((task) {
        final parts = task.split('|');
        return <String, dynamic>{
          'title': parts[0],
          'completed': parts[1] == 'true',
        };
      }).toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = _tasks.map((task) {
      return '${task['title']}|${task['completed']}';
    }).toList();
    await prefs.setStringList('tasks', taskList);
    await prefs.setInt('totalTasks', _tasks.length);
    await prefs.setInt(
      'completedTasks',
      _tasks.where((task) => task['completed'] == true).length,
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(<String, dynamic>{
          'title': _taskController.text,
          'completed': false,
        });
        _taskController.clear();
      });
      _saveTasks();
      Navigator.pop(context);
    }
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['completed'] = !(_tasks[index]['completed'] as bool);
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: _tasks.isEmpty
          ? const Center(child: Text('No tasks yet. Add one!'))
          : ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: task['completed'] as bool,
                      onChanged: (_) => _toggleTask(index),
                    ),
                    title: Text(
                      task['title'] as String,
                      style: TextStyle(
                        decoration: (task['completed'] as bool)
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTask(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add New Task'),
              content: TextField(
                controller: _taskController,
                decoration: const InputDecoration(hintText: 'Task title'),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(onPressed: _addTask, child: const Text('Add')),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
