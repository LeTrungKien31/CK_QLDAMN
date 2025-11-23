// lib/screens/attendance/qr_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class QRAttendanceScreen extends StatefulWidget {
  final int activityId;

  const QRAttendanceScreen({super.key, required this.activityId});

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen> {
  final ApiService _apiService = ApiService();
  String? _qrData;
  bool _isGenerating = false;
  int _validMinutes = 5;

  Future<void> _generateQRCode() async {
    setState(() => _isGenerating = true);
    try {
      final qrData = await _apiService.generateQRCode(
        widget.activityId,
        _validMinutes,
      );
      setState(() {
        _qrData = qrData;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _generateQRCode();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh QR Code'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: user.isStudent()
          ? const QRScannerView()
          : _buildTeacherView(),
    );
  }

  Widget _buildTeacherView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Mã QR điểm danh',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sinh viên quét mã này để điểm danh',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isGenerating)
              const CircularProgressIndicator()
            else if (_qrData != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 280.0,
                  backgroundColor: Colors.white,
                ),
              )
            else
              const Text('Không thể tạo mã QR'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Thời gian hiệu lực:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _validMinutes,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 phút')),
                    DropdownMenuItem(value: 10, child: Text('10 phút')),
                    DropdownMenuItem(value: 15, child: Text('15 phút')),
                    DropdownMenuItem(value: 30, child: Text('30 phút')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _validMinutes = value);
                      _generateQRCode();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateQRCode,
              icon: const Icon(Icons.refresh),
              label: const Text('Tạo mã mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Mã QR sẽ hết hạn sau thời gian đã chọn. Tạo mã mới khi cần.',
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

class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  final ApiService _apiService = ApiService();
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String code) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      final result = await _apiService.verifyQRCode(code);
      
      if (result['valid'] == true) {
        await _apiService.markAttendance({
          'registration_id': result['registration_id'],
          'activity_id': result['activity_id'],
          'student_id': result['student_id'],
          'attendance_method': 'qr_code',
          'status': 'present',
        });

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              title: const Text('Điểm danh thành công!'),
              content: const Text('Bạn đã điểm danh thành công cho hoạt động này.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Mã QR không hợp lệ');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.error,
              color: Colors.red,
              size: 64,
            ),
            title: const Text('Lỗi'),
            content: Text(e.toString()),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleBarcode(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Quét mã QR để điểm danh',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: cameraController.torchState,
                  builder: (context, state, child) {
                    switch (state) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.amber);
                    }
                  },
                ),
                onPressed: () => cameraController.toggleTorch(),
              ),
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}