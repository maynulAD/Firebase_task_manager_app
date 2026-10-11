import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection('users').doc(_uid).collection('tasks');

  Stream<List<TaskItem>> watchTasks() => _tasks
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TaskItem.fromMap(doc.id, doc.data()))
          .toList());

  Future<void> addTask(TaskItem task) async {
    final now = DateTime.now();
    final data = task.toMap(includeCreatedAt: false);
    data['createdAt'] = Timestamp.fromDate(now);
    final doc = await _tasks.add(data);
    await doc.update({'id': doc.id});
  }

  Future<void> updateTask(TaskItem task) =>
      _tasks.doc(task.id).update(task.toMap(includeCreatedAt: false));

  Future<void> setCompleted(TaskItem task, bool completed) =>
      _tasks.doc(task.id).update({'isCompleted': completed});

  Future<void> deleteTask(String id) => _tasks.doc(id).delete();

  Future<TaskItem?> getTask(String id) async {
    final doc = await _tasks.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return TaskItem.fromMap(doc.id, doc.data()!);
  }
}
