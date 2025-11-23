// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<User> _users = [];
  bool _isLoading = false;
  String? _selectedRole;
  final List<String> _roles = ['All', 'admin', 'teacher', 'student'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getUsers(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        role: _selectedRole != null && _selectedRole != 'All' ? _selectedRole : null,
      );
      setState(() {
        _users = users;
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

  void _showUserDialog({User? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user?.username);
    final emailController = TextEditingController(text: user?.email);
    final fullNameController = TextEditingController(text: user?.fullName);
    final phoneController = TextEditingController(text: user?.phone);
    final passwordController = TextEditingController();
    
    // Student fields
    final studentCodeController = TextEditingController();
    final classNameController = TextEditingController();
    final majorController = TextEditingController();
    final academicYearController = TextEditingController();
    final addressController = TextEditingController();
    DateTime? dateOfBirth;
    
    String selectedRole = user?.role ?? 'student';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa người dùng' : 'Thêm người dùng mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: !isEdit,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ và tên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  if (!isEdit)
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu *',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (!isEdit && (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (!isEdit && value!.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò *',
                      prefixIcon: Icon(Icons.admin_panel_settings),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                      DropdownMenuItem(value: 'teacher', child: Text('Giảng viên')),
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),
                  
                  // Student-specific fields
                  if (selectedRole == 'student' && !isEdit) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Thông tin sinh viên',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: studentCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã sinh viên *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (selectedRole == 'student' && (value == null || value.isEmpty)) {
                          return 'Vui lòng nhập mã sinh viên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Lớp',
                        prefixIcon: Icon(Icons.class_),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: majorController,
                      decoration: const InputDecoration(
                        labelText: 'Ngành học',
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: academicYearController,
                      decoration: const InputDecoration(
                        labelText: 'Niên khóa',
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'VD: 2020-2024',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1980),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dateOfBirth = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          dateOfBirth != null
                              ? DateFormat('dd/MM/yyyy').format(dateOfBirth!)
                              : 'Chọn ngày sinh',
                          style: TextStyle(
                            color: dateOfBirth != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final userData = {
                  'username': usernameController.text.trim(),
                  'email': emailController.text.trim(),
                  'full_name': fullNameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'role': selectedRole,
                  if (!isEdit) 'password': passwordController.text,
                  
                  // Student fields
                  if (selectedRole == 'student' && !isEdit) ...{
                    'student_code': studentCodeController.text.trim(),
                    'class_name': classNameController.text.trim().isNotEmpty 
                        ? classNameController.text.trim() 
                        : null,
                    'major': majorController.text.trim().isNotEmpty 
                        ? majorController.text.trim() 
                        : null,
                    'academic_year': academicYearController.text.trim().isNotEmpty 
                        ? academicYearController.text.trim() 
                        : null,
                    'date_of_birth': dateOfBirth?.toIso8601String(),
                    'address': addressController.text.trim().isNotEmpty 
                        ? addressController.text.trim() 
                        : null,
                  },
                };

                try {
                  if (isEdit) {
                    await _apiService.updateUser(user.id!, userData);
                  } else {
                    await _apiService.createUser(userData);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit
                            ? 'Đã cập nhật người dùng'
                            : 'Đã thêm người dùng mới'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUsers();
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
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _apiService.deleteUser(user.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa người dùng'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadUsers();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _loadUsers();
                    }
                  },
                  onSubmitted: (value) => _loadUsers(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = _selectedRole == role ||
                          (_selectedRole == null && role == 'All');
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getRoleText(role)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRole = role == 'All' ? null : role;
                            });
                            _loadUsers();
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
                : _users.isEmpty
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
                              'Không tìm thấy người dùng',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user.role),
                                  child: Text(
                                    user.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    Chip(
                                      label: Text(
                                        _getRoleText(user.role),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                                      labelStyle: TextStyle(color: _getRoleColor(user.role)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Chỉnh sửa'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Xóa', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showUserDialog(user: user);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(user);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'teacher':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      case 'All':
        return 'Tất cả';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'teacher':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}