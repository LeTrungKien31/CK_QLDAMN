// lib/screens/report/report_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Mặc định: 30 ngày gần nhất
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getOverallStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _statistics = stats;
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Báo cáo thống kê',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _startDate != null && _endDate != null
                                    ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                                    : 'Chọn khoảng thời gian',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _statistics == null
                    ? const Center(child: Text('Không có dữ liệu'))
                    : RefreshIndicator(
                        onRefresh: _loadStatistics,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thống kê tổng quan
                              const Text(
                                'Tổng quan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.event,
                                      label: 'Tổng hoạt động',
                                      value: _statistics!['total_activities']?.toString() ?? '0',
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.people,
                                      label: 'Sinh viên',
                                      value: _statistics!['total_students']?.toString() ?? '0',
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.app_registration,
                                      label: 'Đăng ký',
                                      value: _statistics!['total_registrations']?.toString() ?? '0',
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.check_circle,
                                      label: 'Đã điểm danh',
                                      value: _statistics!['total_attendances']?.toString() ?? '0',
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              
                              // Tỷ lệ tham gia
                              const Text(
                                'Tỷ lệ tham gia',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildAttendanceRate(
                                        'Tỷ lệ điểm danh',
                                        _statistics!['attendance_rate'] ?? 0.0,
                                        Colors.green,
                                      ),
                                      const Divider(height: 32),
                                      _buildAttendanceRate(
                                        'Tỷ lệ vắng',
                                        100 - (_statistics!['attendance_rate'] ?? 0.0),
                                        Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Hoạt động theo loại
                              if (_statistics!['activities_by_type'] != null) ...[
                                const Text(
                                  'Hoạt động theo loại',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: (_statistics!['activities_by_type'] as List)
                                          .map((item) => _buildTypeRow(
                                                item['activity_type'] ?? 'Khác',
                                                item['count'] ?? 0,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),

                              // Top sinh viên tham gia
                              if (_statistics!['top_students'] != null) ...[
                                const Text(
                                  'Sinh viên tích cực',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: (_statistics!['top_students'] as List)
                                        .take(10)
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final student = entry.value;
                                      return _buildStudentRow(
                                        index + 1,
                                        student['full_name'] ?? 'N/A',
                                        student['student_code'] ?? '',
                                        student['attendance_count'] ?? 0,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRate(String label, double rate, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeRow(String type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: const TextStyle(fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(int rank, String name, String code, int count) {
    Color rankColor;
    IconData rankIcon;
    
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.blue;
      rankIcon = Icons.person;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rankColor.withOpacity(0.2),
        child: rank <= 3
            ? Icon(rankIcon, color: rankColor, size: 20)
            : Text(
                rank.toString(),
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(code),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$count hoạt động',
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}