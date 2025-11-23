// lib/screens/activity/activity_form_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../services/api_service.dart';

class ActivityFormScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;
  
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _registrationDeadline;
  String? _activityType;
  bool _isLoading = false;

  final List<String> _activityTypes = [
    'Học thuật',
    'Thể thao',
    'Văn hóa',
    'Tình nguyện',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity?.title);
    _descriptionController = TextEditingController(text: widget.activity?.description);
    _locationController = TextEditingController(text: widget.activity?.location);
    _maxParticipantsController = TextEditingController(
      text: widget.activity?.maxParticipants?.toString(),
    );
    
    _startTime = widget.activity?.startTime;
    _endTime = widget.activity?.endTime;
    _registrationDeadline = widget.activity?.registrationDeadline;
    _activityType = widget.activity?.activityType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, String field) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          switch (field) {
            case 'start':
              _startTime = selectedDateTime;
              break;
            case 'end':
              _endTime = selectedDateTime;
              break;
            case 'deadline':
              _registrationDeadline = selectedDateTime;
              break;
          }
        });
      }
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activityData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'start_time': _startTime!.toIso8601String(),
        'end_time': _endTime!.toIso8601String(),
        'registration_deadline': _registrationDeadline?.toIso8601String(),
        'max_participants': _maxParticipantsController.text.isNotEmpty
            ? int.parse(_maxParticipantsController.text)
            : null,
        'activity_type': _activityType,
        'status': 'upcoming',
      };

      if (widget.activity == null) {
        await _apiService.createActivity(activityData);
      } else {
        await _apiService.updateActivity(widget.activity!.id!, activityData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.activity == null
                ? 'Đã tạo hoạt động thành công'
                : 'Đã cập nhật hoạt động thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'Tạo hoạt động mới' : 'Chỉnh sửa hoạt động'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveActivity,
              child: const Text(
                'LƯU',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Tên hoạt động *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên hoạt động';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Địa điểm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _activityType,
                    decoration: InputDecoration(
                      labelText: 'Loại hoạt động',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _activityTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _activityType = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDateTime(context, 'start'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Thời gian bắt đầu *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _startTime != null
                            ? dateFormat.format(_startTime!)
                            : 'Chọn thời gian bắt đầu',
                        style: TextStyle(
                          color: _startTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDateTime(context, 'end'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Thời gian kết thúc *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.timer_off),
                      ),
                      child: Text(
                        _endTime != null
                            ? dateFormat.format(_endTime!)
                            : 'Chọn thời gian kết thúc',
                        style: TextStyle(
                          color: _endTime != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDateTime(context, 'deadline'),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Hạn đăng ký',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.event_busy),
                        suffixIcon: _registrationDeadline != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _registrationDeadline = null);
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _registrationDeadline != null
                            ? dateFormat.format(_registrationDeadline!)
                            : 'Chọn hạn đăng ký (tùy chọn)',
                        style: TextStyle(
                          color: _registrationDeadline != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _maxParticipantsController,
                    decoration: InputDecoration(
                      labelText: 'Số lượng tối đa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.people),
                      hintText: 'Không giới hạn',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = int.tryParse(value);
                        if (number == null || number <= 0) {
                          return 'Vui lòng nhập số hợp lệ';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Các trường đánh dấu (*) là bắt buộc',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}