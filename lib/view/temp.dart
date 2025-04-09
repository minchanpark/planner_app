import 'package:flutter/material.dart';
import 'package:planner/theme/theme.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({Key? key}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // Sample task data (would come from a model in real implementation)
  final String taskTitle = "디자인 피드백 반영하기";
  final String taskDescription = "SOI 앱 디자인 검토 후 수정사항 반영하기";
  final DateTime dueDate = DateTime.now().add(const Duration(days: 2));
  final String category = "디자인";
  final int priority = 2; // 1-3 scale where 3 is highest
  final bool isCompleted = false;

  // Controller for task notes
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
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
          icon: const Icon(Icons.arrow_back, color: Color(0xff634D45)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "태스크 상세",
          style: AppTheme.textTheme.textTheme.displayMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xff634D45)),
            onPressed: () {
              // Show options menu
              _showOptionsMenu(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task completion status
              Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    activeColor: const Color(0xff634D45),
                    onChanged: (value) {
                      setState(() {
                        // In real app would update in view model
                      });
                    },
                  ),
                  Text(
                    isCompleted ? "완료됨" : "진행중",
                    style: AppTheme.textTheme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  // Priority indicator
                  _buildPriorityIndicator(priority),
                ],
              ),

              const SizedBox(height: 24),

              // Task title
              Text(
                taskTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff232121),
                ),
              ),

              const SizedBox(height: 16),

              // Task description
              Text(
                taskDescription,
                style: AppTheme.textTheme.textTheme.labelMedium,
              ),

              const SizedBox(height: 24),

              // Due date section
              _buildInfoRow(Icons.calendar_today, "마감일",
                  "${dueDate.year}년 ${dueDate.month}월 ${dueDate.day}일"),

              const SizedBox(height: 16),

              // Category section
              _buildInfoRow(Icons.folder_outlined, "카테고리", category),

              const SizedBox(height: 24),

              // Divider
              const Divider(thickness: 1),

              const SizedBox(height: 24),

              // Notes section
              Text(
                "메모",
                style: AppTheme.textTheme.textTheme.displayMedium,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "메모를 입력하세요...",
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

              // Attachments section
              Text(
                "첨부파일",
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
                    // Save task logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff634D45),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "저장하기",
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

  Widget _buildPriorityIndicator(int priority) {
    Color priorityColor;
    String priorityText;

    switch (priority) {
      case 3:
        priorityColor = Colors.red;
        priorityText = "높음";
        break;
      case 2:
        priorityColor = Colors.orange;
        priorityText = "중간";
        break;
      default:
        priorityColor = Colors.green;
        priorityText = "낮음";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priorityColor),
      ),
      child: Text(
        priorityText,
        style: TextStyle(
          color: priorityColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xff634D45),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: AppTheme.textTheme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: AppTheme.textTheme.textTheme.labelMedium,
        ),
      ],
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xff634D45)),
                title: const Text("수정하기"),
                onTap: () {
                  Navigator.pop(context);
                  // Edit logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xff634D45)),
                title: const Text("공유하기"),
                onTap: () {
                  Navigator.pop(context);
                  // Share logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("삭제하기", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Delete logic
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
