import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../models/task.dart';
import '../services/organization_service.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final Organization organization;

  const OrganizationDetailScreen({super.key, required this.organization});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final OrganizationService _organizationService = OrganizationService();

  late Future<List<Task>> _tasksFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _organizationService.fetchTasksByOrganization(
      widget.organization.id,
    );
  }

  void _reloadTasks() {
    setState(() {
      _tasksFuture = _organizationService.fetchTasksByOrganization(
        widget.organization.id,
      );
    });
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _changeTaskStatus(Task task, String? newStatus) async {
    if (newStatus == null || newStatus == task.estado || _isUpdatingStatus) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await _organizationService.updateTaskStatus(
        tareaId: task.id,
        estado: newStatus,
      );

      if (!mounted) {
        return;
      }

      _reloadTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el estado: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  List<Task> _filterByEstado(List<Task> tasks, String estado) {
    return tasks.where((task) => task.estado == estado).toList();
  }

  Color _columnAccentColor(String estado) {
    switch (estado) {
      case 'todo':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.organization.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.business, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.organization.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.organization.id}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No se pudieron cargar las tareas.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final List<Task> tasks = snapshot.data ?? [];
                final List<Task> todoTasks = _filterByEstado(tasks, 'todo');
                final List<Task> inProgressTasks = _filterByEstado(
                  tasks,
                  'in_progress',
                );
                final List<Task> completedTasks = _filterByEstado(
                  tasks,
                  'completed',
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tablero de tareas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Chip(
                            label: Text('${tasks.length} tareas'),
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 1080,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _KanbanColumn(
                                  title: 'To do',
                                  color: _columnAccentColor('todo'),
                                  tasks: todoTasks,
                                  isUpdatingStatus: _isUpdatingStatus,
                                  formatDate: _formatDate,
                                  onStatusChanged: _changeTaskStatus,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _KanbanColumn(
                                  title: 'In progress',
                                  color: _columnAccentColor('in_progress'),
                                  tasks: inProgressTasks,
                                  isUpdatingStatus: _isUpdatingStatus,
                                  formatDate: _formatDate,
                                  onStatusChanged: _changeTaskStatus,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _KanbanColumn(
                                  title: 'Done',
                                  color: _columnAccentColor('completed'),
                                  tasks: completedTasks,
                                  isUpdatingStatus: _isUpdatingStatus,
                                  formatDate: _formatDate,
                                  onStatusChanged: _changeTaskStatus,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final bool? created = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => CreateTaskScreen(
                  organizacionId: widget.organization.id,
                  usuarios: widget.organization.usuarios,
                ),
              ),
            );

            if (created == true) {
              _reloadTasks();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_task),
              SizedBox(width: 10),
              Text(
                'Crear tarea',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final bool isUpdatingStatus;
  final String Function(DateTime) formatDate;
  final Future<void> Function(Task, String?) onStatusChanged;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tasks,
    required this.isUpdatingStatus,
    required this.formatDate,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: color.withOpacity(0.15),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'Sin tareas',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = tasks[index];

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailScreen(task: task),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inicio: ${formatDate(task.fechaInicio)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Fin: ${formatDate(task.fechaFin)}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: task.estado,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Estado',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'todo',
                                      child: Text('To do'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'in_progress',
                                      child: Text('In progress'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text('Done'),
                                    ),
                                  ],
                                  onChanged: isUpdatingStatus
                                      ? null
                                      : (String? value) =>
                                            onStatusChanged(task, value),
                                ),
                                if (task.usuarios.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: task.usuarios
                                        .map(
                                          (user) => Chip(
                                            label: Text(user.name),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
