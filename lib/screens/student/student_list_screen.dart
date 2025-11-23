// lib/screens/student/student_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student.dart';
import '../../services/api_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Student> _students = [];
  bool _isLoading = false;
  String? _selectedClass;
  final List<String> _classes = ['All', 'CNTT1', 'CNTT2', 'CNTT3', 'CNTT4'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _apiService.getStudents(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        className: _selectedClass != null && _selectedClass != 'All' 
            ? _selectedClass 
            : null,
      );
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showStudentDetail(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    student.user?.fullName[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  student.user?.fullName ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text(student.studentCode),
                  backgroundColor: Colors.blue.shade50,
                ),
              ),
              const SizedBox(height: 32),
              _DetailRow(
                icon: Icons.email,
                label: 'Email',
                value: student.user?.email ?? 'N/A',
              ),
              if (student.user?.phone != null)
                _DetailRow(
                  icon: Icons.phone,
                  label: 'Số điện thoại',
                  value: student.user!.phone!,
                ),
              if (student.className != null)
                _DetailRow(
                  icon: Icons.class_,
                  label: 'Lớp',
                  value: student.className!,
                ),
              if (student.major != null)
                _DetailRow(
                  icon: Icons.school,
                  label: 'Ngành',
                  value: student.major!,
                ),
              if (student.academicYear != null)
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Niên khóa',
                  value: student.academicYear!,
                ),
              if (student.dateOfBirth != null)
                _DetailRow(
                  icon: Icons.cake,
                  label: 'Ngày sinh',
                  value: DateFormat('dd/MM/yyyy').format(student.dateOfBirth!),
                ),
              if (student.address != null)
                _DetailRow(
                  icon: Icons.home,
                  label: 'Địa chỉ',
                  value: student.address!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sinh viên...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _loadStudents();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    _loadStudents();
                  }
                },
                onSubmitted: (value) => _loadStudents(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final className = _classes[index];
                    final isSelected = _selectedClass == className ||
                        (_selectedClass == null && className == 'All');
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(className),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedClass = className == 'All' ? null : className;
                          });
                          _loadStudents();
                        },
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade700,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Không tìm thấy sinh viên',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () => _showStudentDetail(student),
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  student.user?.fullName[0].toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                student.user?.fullName ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    student.studentCode,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (student.className != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.class_,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          student.className!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}