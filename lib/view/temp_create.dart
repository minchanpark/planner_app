import 'package:flutter/material.dart';
import 'package:planner/theme/theme.dart';
import 'package:intl/intl.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({Key? key}) : super(key: key);

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = "개인";
  int _selectedPriority = 2;

  final List<String> _categories = ["개인", "업무", "학업", "디자인", "프로젝트"];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xff634D45)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "새 태스크",
          style: AppTheme.textTheme.textTheme.displayMedium,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title input
              Text(
                "제목",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "태스크 제목을 입력하세요",
                  hintStyle: AppTheme.textTheme.textTheme.labelMedium,
                  filled: true,
                  fillColor: const Color(0xffF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Description input
              Text(
                "설명",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "태스크 설명을 입력하세요",
                  hintStyle: AppTheme.textTheme.textTheme.labelMedium,
                  filled: true,
                  fillColor: const Color(0xffF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Due date selector
              Text(
                "마감일",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xff634D45),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                        style: AppTheme.textTheme.textTheme.labelMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xff634D45),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Time selector
              InkWell(
                onTap: () => _selectTime(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xff634D45),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                        style: AppTheme.textTheme.textTheme.labelMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xff634D45),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category selector
              Text(
                "카테고리",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xff634D45)),
                  style: AppTheme.textTheme.textTheme.labelMedium,
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        _selectedCategory = newValue;
                      }
                    });
                  },
                  items:
                      _categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Priority selector
              Text(
                "우선순위",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriorityOption(1, "낮음", Colors.green),
                  _buildPriorityOption(2, "중간", Colors.orange),
                  _buildPriorityOption(3, "높음", Colors.red),
                ],
              ),

              const SizedBox(height: 24),

              // Divider
              const Divider(thickness: 1),

              const SizedBox(height: 24),

              // Attachments section
              Text(
                "첨부파일 추가",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),

              const SizedBox(height: 16),

              // Attachment buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildAttachmentButton(Icons.image, "이미지"),
                  const SizedBox(width: 16),
                  _buildAttachmentButton(Icons.mic, "음성"),
                  const SizedBox(width: 16),
                  _buildAttachmentButton(Icons.videocam, "비디오"),
                ],
              ),

              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _saveTask();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff634D45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "태스크 생성",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(int priority, String label, Color color) {
    bool isSelected = _selectedPriority == priority;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        // Attachment logic
      },
      icon: Icon(icon, color: const Color(0xff634D45)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xff634D45),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xff634D45)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff634D45),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff634D45),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() {
    // In a real implementation, this would save to a database or state management solution

    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목을 입력해주세요")),
      );
      return;
    }

    // Validation passed, proceed to save
    Navigator.of(context).pop();
  }
}
