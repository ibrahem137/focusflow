import 'package:flutter/material.dart';

import '../../data/models/task_model.dart';

import 'package:focus_flow/core/constants/theme/app_colors.dart';

class AddTaskDialog extends StatefulWidget {
  final TaskModel? task;
  final Future<bool> Function({
    required String title,
    required String category,
    required int xp,
  })
  onAddTask;

  const AddTaskDialog({super.key, this.task, required this.onAddTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late final TextEditingController _titleController;

  String _selectedCategory = 'Learning';
  int _selectedXp = 20;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final secondaryText = colors.onSurfaceVariant;

    final softSurface = theme.brightness == Brightness.dark
        ? colors.surfaceContainerHighest
        : const Color(0xFFF5F3FF);

    final borderColor = theme.brightness == Brightness.dark
        ? colors.outlineVariant
        : const Color(0xFFE5E7EB);

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: colors.error)),
            // Header

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_task_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task == null ? 'Add New Task' : 'Edit Task',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Small steps. Big progress.',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close_rounded, color: secondaryText),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Task
            Text(
              'Task',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What do you want to do?',
                hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                filled: true,
                fillColor: softSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) {
                _submitTask();
              },
            ),

            const SizedBox(height: 22),

            // Category
            Text(
              'Category',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  <String>{
                    'Learning',
                    'Work',
                    'Personal',
                    _selectedCategory,
                  }.map((category) {
                    final selected = _selectedCategory == category;

                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 15,
                            color: selected ? AppColors.primary : secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Text(category),
                        ],
                      ),
                      selected: selected,
                      showCheckmark: false,
                      backgroundColor: softSurface,
                      selectedColor: AppColors.primary.withValues(alpha: 0.16),
                      side: BorderSide(
                        color: selected ? AppColors.primary : borderColor,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primary : secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  }).toList(),
            ),

            const SizedBox(height: 22),

            // Reward
            if (widget.task != null)
              const Text('The original XP reward is kept when editing.'),
            Text(
              'Reward',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <int>{20, 40, 50, _selectedXp}.map((xp) {
                final selected = _selectedXp == xp;

                return ChoiceChip(
                  label: Text('+$xp XP'),
                  selected: selected,
                  showCheckmark: false,
                  backgroundColor: softSurface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.16),
                  side: BorderSide(
                    color: selected ? AppColors.primary : borderColor,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: widget.task != null
                      ? null
                      : (_) {
                          setState(() {
                            _selectedXp = xp;
                          });
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: secondaryText,
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _submitTask,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        widget.task == null ? 'Add Task' : 'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task?.title);
    _selectedCategory = widget.task?.category ?? 'Learning';
    _selectedXp = widget.task?.xp ?? 20;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Learning':
        return Icons.school_rounded;

      case 'Work':
        return Icons.code_rounded;

      case 'Personal':
        return Icons.person_rounded;

      default:
        return Icons.task_alt_rounded;
    }
  }

  Future<void> _submitTask() async {
    final title = _titleController.text.trim();
    if (_saving) return;
    if (title.isEmpty) {
      setState(() => _error = 'Enter a task title.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onAddTask(
      title: title,
      category: _selectedCategory,
      xp: _selectedXp,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = 'Could not save this task. Please try again.';
      });
    }
  }
}
