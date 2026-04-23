import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../services/organization_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final String organizacionId;
  final List<OrganizationUser> usuarios;

  const CreateTaskScreen({
    super.key,
    required this.organizacionId,
    required this.usuarios,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OrganizationService _organizationService = OrganizationService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  late final Set<String> _selectedUsuarioIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start with all organization users selected by default to preserve current behavior.
    _selectedUsuarioIds = widget.usuarios
        .map((OrganizationUser user) => user.id)
        .toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      filled: true,
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona fecha de inicio',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _startDateController.text = _formatDate(_startDate!);

      // If start date moves forward, clear end date if it becomes invalid.
      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = null;
        _endDateController.clear();
      }
    });

    _formKey.currentState?.validate();
  }

  Future<void> _pickEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _endDate ?? _startDate ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      helpText: 'Selecciona fecha de fin',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      _endDateController.text = _formatDate(_endDate!);
    });

    _formKey.currentState?.validate();
  }

  DateTime _normalizeStartDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 8, 0, 0);
  }

  DateTime _normalizeEndDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 17, 0, 0);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    if (_selectedUsuarioIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un usuario')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _organizationService.createTaskByOrganization(
        organizacionId: widget.organizacionId,
        titulo: _titleController.text.trim(),
        fechaInicio: _normalizeStartDate(_startDate!),
        fechaFin: _normalizeEndDate(_endDate!),
        usuarios: _selectedUsuarioIds.toList(),
        estado: 'todo', // Default status for new tasks
      );

      print('Formulario válido. Datos listos para la Fase 4');

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo crear la tarea: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openUserSelector() async {
    if (widget.usuarios.isEmpty) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Selecciona usuarios',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.usuarios.length,
                        itemBuilder: (BuildContext context, int index) {
                          final OrganizationUser user = widget.usuarios[index];

                          return CheckboxListTile(
                            value: _selectedUsuarioIds.contains(user.id),
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  _selectedUsuarioIds.add(user.id);
                                } else {
                                  _selectedUsuarioIds.remove(user.id);
                                }
                              });
                              // Update parent state so the main screen reflects changes
                              setState(() {});
                            },
                            title: Text(user.name),
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Listo'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Tarea')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: _buildInputDecoration(
                            label: 'Título',
                            hint: 'Escribe el título de la tarea',
                            icon: Icons.title,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El título es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: _pickStartDate,
                          decoration:
                              _buildInputDecoration(
                                label: 'Fecha de inicio',
                                hint: 'Selecciona una fecha',
                                icon: Icons.event,
                              ).copyWith(
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                          validator: (String? value) {
                            if (_startDate == null) {
                              return 'La fecha de inicio es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: _pickEndDate,
                          decoration:
                              _buildInputDecoration(
                                label: 'Fecha de fin',
                                hint: 'Selecciona una fecha',
                                icon: Icons.event_available,
                              ).copyWith(
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                          validator: (String? value) {
                            if (_endDate == null) {
                              return 'La fecha de fin es obligatoria';
                            }
                            if (_startDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              return 'La fecha de fin no puede ser anterior a la fecha de inicio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        if (widget.usuarios.isEmpty)
                          const Text(
                            'Esta organización no tiene usuarios para asignar.',
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: _openUserSelector,
                                child: InputDecorator(
                                  decoration:
                                      _buildInputDecoration(
                                        label: 'Usuarios asignados',
                                        hint: 'Selecciona usuarios',
                                        icon: Icons.group,
                                      ).copyWith(
                                        labelText: 'Usuarios asignados',
                                        suffixIcon: const Icon(
                                          Icons.arrow_drop_down,
                                        ),
                                      ),
                                  child: Text(
                                    _selectedUsuarioIds.isEmpty
                                        ? 'Pulsa para seleccionar'
                                        : widget.usuarios
                                            .where(
                                              (u) => _selectedUsuarioIds.contains(
                                                u.id,
                                              ),
                                            )
                                            .map((u) => u.name)
                                            .join(', '),
                                    style: TextStyle(
                                      color:
                                          _selectedUsuarioIds.isEmpty
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
