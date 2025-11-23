// lib/screens/activity/activity_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../attendance/qr_attendance_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final ApiService _apiService = ApiService();
  Activity? _activity;
  List<dynamic> _registrations = [];
  bool _isLoading = true;
  bool _isRegistered = false;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _loadActivityDetail();
  }

  Future<void> _loadActivityDetail() async {
    setState(() => _isLoading = true);
    try {
      final activity = await _apiService.getActivityById(widget.activityId);
      final registrations = await _apiService.getActivityRegistrations(widget.activityId);
      
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final isRegistered = registrations.any((r) => 
        r['student']?['user_id'] == user?.id
      );
      
      setState(() {
        _activity = activity;
        _registrations = registrations;
        _isRegistered = isRegistered;
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

  Future<void> _registerActivity() async {
    setState(() => _isRegistering = true);
    try {
      await _apiService.registerActivity(widget.activityId);
      await _loadActivityDetail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công!'),
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
    setState(() => _isRegistering = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Không tìm thấy hoạt động')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hoạt động'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (user.isAdmin() || user.isTeacher())
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'qr',
                  child: ListTile(
                    leading: Icon(Icons.qr_code),
                    title: Text('Tạo mã QR điểm danh'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'registrations',
                  child: ListTile(
                    leading: Icon(Icons.list),
                    title: Text('Danh sách đăng ký'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'qr':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRAttendanceScreen(
                          activityId: widget.activityId,
                        ),
                      ),
                    );
                    break;
                  case 'registrations':
                    _showRegistrationsList();
                    break;
                  case 'delete':
                    _showDeleteDialog();
                    break;
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivityDetail,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_activity!.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _activity!.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 64),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                _activity!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Thời gian bắt đầu',
                value: dateFormat.format(_activity!.startTime),
              ),
              _InfoRow(
                icon: Icons.timer_off,
                label: 'Thời gian kết thúc',
                value: dateFormat.format(_activity!.endTime),
              ),
              if (_activity!.location != null)
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Địa điểm',
                  value: _activity!.location!,
                ),
              if (_activity!.activityType != null)
                _InfoRow(
                  icon: Icons.category,
                  label: 'Loại hoạt động',
                  value: _activity!.activityType!,
                ),
              _InfoRow(
                icon: Icons.people,
                label: 'Số người đăng ký',
                value: '${_registrations.length}${_activity!.maxParticipants != null ? "/${_activity!.maxParticipants}" : ""}',
              ),
              if (_activity!.registrationDeadline != null)
                _InfoRow(
                  icon: Icons.event_busy,
                  label: 'Hạn đăng ký',
                  value: dateFormat.format(_activity!.registrationDeadline!),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _activity!.description ?? 'Không có mô tả',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: user.isStudent() && !_isRegistered && _activity!.isUpcoming()
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _registerActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ĐĂNG KÝ THAM GIA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  void _showRegistrationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách đăng ký',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_registrations.length} sinh viên',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _registrations.length,
                itemBuilder: (context, index) {
                  final reg = _registrations[index];
                  final student = reg['student'];
                  final user = student?['user'];
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user?['full_name']?[0] ?? '?'),
                    ),
                    title: Text(user?['full_name'] ?? 'N/A'),
                    subtitle: Text(student?['student_code'] ?? ''),
                    trailing: Chip(
                      label: Text(reg['status'] ?? 'registered'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hoạt động'),
        content: const Text('Bạn có chắc chắn muốn xóa hoạt động này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteActivity(widget.activityId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa hoạt động')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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