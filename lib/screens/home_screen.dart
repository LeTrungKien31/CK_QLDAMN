import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'activity/activity_list_screen.dart';
import 'student/student_list_screen.dart';
import 'attendance/attendance_screen.dart';
import 'report/report_screen.dart';
import 'admin/user_management_screen.dart';
import 'admin/backup_restore_screen.dart';
import 'auth/change_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser!;
    
    final List<Widget> screens = user.isAdmin() || user.isTeacher()
        ? [
            const ActivityListScreen(),
            const StudentListScreen(),
            const AttendanceScreen(),
            const ReportScreen(),
          ]
        : [
            const ActivityListScreen(), // Student view
            const AttendanceScreen(),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Sinh viên'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.fullName[0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user.fullName),
                  subtitle: Text(user.role.toUpperCase()),
                ),
              ),
              const PopupMenuDivider(),
              if (user.isAdmin()) ...[
                const PopupMenuItem(
                  value: 'users',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Quản lý người dùng'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'backup',
                  child: ListTile(
                    leading: Icon(Icons.backup),
                    title: Text('Sao lưu & Phục hồi'),
                  ),
                ),
                const PopupMenuDivider(),
              ],
              const PopupMenuItem(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Đổi mật khẩu'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Đăng xuất'),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'users':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  );
                  break;
                case 'backup':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BackupRestoreScreen(),
                    ),
                  );
                  break;
                case 'change_password':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        items: user.isAdmin() || user.isTeacher()
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Hoạt động',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Sinh viên',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'Điểm danh',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Báo cáo',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.event),
                  label: 'Hoạt động',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'Điểm danh',
                ),
              ],
      ),
      floatingActionButton: _selectedIndex == 0 &&
              (user.isAdmin() || user.isTeacher())
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityFormScreen(),
                  ),
                );
              },
              backgroundColor: Colors.blue.shade700,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
