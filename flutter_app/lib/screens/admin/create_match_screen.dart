import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _awayTeamNameController = TextEditingController();
  final _sectorNameController = TextEditingController(text: 'Фан-сектор');
  final _capacityController = TextEditingController(text: '100');
  final _descriptionController = TextEditingController();

  List<Team> _teams = [];
  List<Arena> _arenas = [];
  Team? _selectedHomeTeam;
  Arena? _selectedArena;

  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 7));
  DateTime _bookingOpenAt = DateTime.now().add(const Duration(days: 1));
  DateTime _bookingCloseAt = DateTime.now().add(const Duration(days: 6));
  bool _isHome = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final t = await ApiService().getTeams();
      final a = await ApiService().getArenas();
      setState(() {
        _teams = t;
        _arenas = a;
        _selectedHomeTeam = t.isNotEmpty ? t.first : null;
        _selectedArena = a.isNotEmpty ? a.first : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime(BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final full = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    onPicked(full);
  }

  Future<void> _submit() async {
    if (_selectedHomeTeam == null || _selectedArena == null || _awayTeamNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final body = {
        'homeTeamId': _selectedHomeTeam!.id,
        'awayTeamName': _awayTeamNameController.text.trim(),
        'arenaId': _selectedArena!.id,
        'scheduledAt': _scheduledAt.toIso8601String(),
        'bookingOpenAt': _bookingOpenAt.toIso8601String(),
        'bookingCloseAt': _bookingCloseAt.toIso8601String(),
        'isHome': _isHome,
        'fanSector': {
          'name': _sectorNameController.text.trim(),
          'capacity': int.tryParse(_capacityController.text.trim()) ?? 100,
        },
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
      };

      await ApiService().createMatch(body);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.success, content: Text('Матч успешно создан!')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Создание матча')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brandPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Команда хозяев', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Team>(
                        value: _selectedHomeTeam,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceElevated,
                        items: _teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                        onChanged: (v) => setState(() => _selectedHomeTeam = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    placeholder: 'Команда гостей (название)',
                    controller: _awayTeamNameController,
                    icon: Icons.sports_hockey,
                  ),
                  const SizedBox(height: 14),

                  const Text('Арена проведения', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Arena>(
                        value: _selectedArena,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceElevated,
                        items: _arenas.map((a) => DropdownMenuItem(value: a, child: Text('${a.name} (${a.city})'))).toList(),
                        onChanged: (v) => setState(() => _selectedArena = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dates
                  _buildDatePickerRow('Дата матча', _scheduledAt, (d) => setState(() => _scheduledAt = d)),
                  const SizedBox(height: 10),
                  _buildDatePickerRow('Открытие брони', _bookingOpenAt, (d) => setState(() => _bookingOpenAt = d)),
                  const SizedBox(height: 10),
                  _buildDatePickerRow('Закрытие брони', _bookingCloseAt, (d) => setState(() => _bookingCloseAt = d)),
                  const SizedBox(height: 14),

                  // Fan Sector
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          placeholder: 'Сектор',
                          controller: _sectorNameController,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          placeholder: 'Вместимость',
                          controller: _capacityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    placeholder: 'Описание матча',
                    controller: _descriptionController,
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 24),

                  AppPrimaryButton(
                    title: 'СОХРАНИТЬ МАТЧ',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime dt, Function(DateTime) onPicked) {
    return InkWell(
      onTap: () => _pickDateTime(context, dt, onPicked),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: AppTheme.brandPrimary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const Spacer(),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(dt),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
