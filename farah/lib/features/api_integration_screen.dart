import 'package:farah/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiIntegrationScreen extends StatefulWidget {
  const ApiIntegrationScreen({super.key});

  @override
  State<ApiIntegrationScreen> createState() => _ApiIntegrationScreenState();
}

class _ApiIntegrationScreenState extends State<ApiIntegrationScreen> {
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color textDark = AppColors.textPrimary;
  static const Color textLight = AppColors.textSecondary;

  // ✅ رابط Supabase Edge Function الجديد
  static const String SUPABASE_EDGE_URL =
      'https://tzizhccygtgqbkgkhbwif.supabase.co/functions/v1/dynamic-processor';

  final _apiUrlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  String? _selectedHallId;
  String? _selectedHallName;
  bool _isEnabled = false;
  bool _loading = false;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

  late Future<List<Map<String, dynamic>>> _hallsFuture;

  @override
  void initState() {
    super.initState();
    _hallsFuture = _loadProviderHalls();
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadProviderHalls() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final List<Map<String, dynamic>> halls = [];
    for (final field in ['providerId', 'ownerId', 'userId']) {
      final snap = await FirebaseFirestore.instance
          .collection('halls')
          .where(field, isEqualTo: uid)
          .get();
      if (snap.docs.isNotEmpty) {
        for (final doc in snap.docs) {
          halls.add({
            'id': doc.id,
            'name': doc.data()['name'] ?? 'قاعة',
            'data': doc.data(),
          });
        }
        break;
      }
    }
    return halls;
  }

  void _onHallSelected(Map<String, dynamic> hall) {
    final data = hall['data'] as Map<String, dynamic>;
    final integration = data['integration'] as Map<String, dynamic>? ?? {};

    setState(() {
      _selectedHallId = hall['id'];
      _selectedHallName = hall['name'];
      _apiUrlCtrl.text = integration['apiUrl'] ?? '';
      _apiKeyCtrl.text = integration['apiKey'] ?? '';
      _isEnabled = integration['isEnabled'] ?? false;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('الربط البرمجي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hallsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          final halls = snap.data ?? [];
          if (halls.isEmpty) return _buildNoHalls();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroCard(),
                const SizedBox(height: 16),
                _buildHallSelector(halls),
                if (_selectedHallId != null) ...[
                  const SizedBox(height: 16),
                  _buildOutgoingSection(),
                  const SizedBox(height: 16),
                  _buildIncomingSection(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoHalls() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.api, size: 70, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد قاعات مسجلة',
                style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('أضف قاعة أولاً من لوحة المزود',
                style: TextStyle(color: textLight, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'اربط تطبيق فرح مع نظام الحجز الخاص بقاعتك لمزامنة تلقائية فورية (بدون تعارض).',
              style: TextStyle(color: textDark, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallSelector(List<Map<String, dynamic>> halls) {
    return _buildSection(
      title: 'اختر القاعة',
      icon: Icons.storefront_outlined,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedHallId,
            hint: const Text('اختر القاعة', style: TextStyle(color: textLight, fontSize: 13)),
            items: halls.map((hall) {
              return DropdownMenuItem<String>(
                value: hall['id'] as String,
                child: Text(hall['name'] as String,
                    style: const TextStyle(color: textDark, fontSize: 14)),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              final hall = halls.firstWhere((h) => h['id'] == val);
              _onHallSelected(hall);
            },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الربط الصادر (من فرح → للقاعة)
  // ═══════════════════════════════════════════════════════════
  Widget _buildOutgoingSection() {
    return _buildSection(
      title: 'الربط الصادر (من فرح → للقاعة)',
      icon: Icons.upload_outlined,
      subtitle: 'عند حجز زبون عبر التطبيق، يُرسَل الحجز تلقائياً لنظام القاعة',
      child: Column(
        children: [
          TextField(
            controller: _apiUrlCtrl,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: textDark, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'API URL (رابط نظام القاعة)',
              labelStyle: const TextStyle(color: textLight, fontSize: 12),
              hintText: 'https://hall-system.com/api/bookings',
              hintStyle: TextStyle(color: textLight.withValues(alpha: 0.5), fontSize: 11),
              prefixIcon: const Icon(Icons.link, color: primary, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiKeyCtrl,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: textDark, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'API Key (المفتاح السري)',
              labelStyle: const TextStyle(color: textLight, fontSize: 12),
              hintText: 'sk_live_xxxxx...',
              hintStyle: TextStyle(color: textLight.withValues(alpha: 0.5), fontSize: 11),
              prefixIcon: const Icon(Icons.key, color: primary, size: 20),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _testing ? null : _testConnection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: _testing
                        ? const Center(child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2)))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_tethering, color: Colors.blue, size: 18),
                              SizedBox(width: 6),
                              Text('اختبار الاتصال', style: TextStyle(
                                  color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _isEnabled = !_isEnabled),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isEnabled
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEnabled ? Colors.green : Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isEnabled ? Icons.check_circle : Icons.circle_outlined,
                        color: _isEnabled ? Colors.green : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isEnabled ? 'مفعّل' : 'معطّل',
                        style: TextStyle(
                          color: _isEnabled ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _testSuccess
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.red.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _testSuccess ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testSuccess ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // الربط الوارد (من القاعة → لفرح)
  // ═══════════════════════════════════════════════════════════
  Widget _buildIncomingSection() {
    final webhookUrl = _getWebhookUrl();
    final webhookSecret = _selectedHallId ?? '';

    return _buildSection(
      title: 'الربط الوارد (من القاعة → لفرح)',
      icon: Icons.download_outlined,
      subtitle: 'أعطِ هذه المعلومات لشركة نظام القاعة ليُرسلوا الحجوزات إلينا تلقائياً',
      child: Column(
        children: [
          _buildCopyField(
            label: 'Webhook URL',
            value: webhookUrl,
            icon: Icons.link,
          ),
          const SizedBox(height: 10),
          _buildCopyField(
            label: 'Webhook Secret',
            value: webhookSecret,
            icon: Icons.key,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أرسل هذه المعلومات لشركة نظام القاعة. سيستخدمونها لإرسال الحجوزات الحضورية إلى تطبيق فرح تلقائياً.',
                    style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ الرابط الجديد (Supabase)
  String _getWebhookUrl() {
    return '$SUPABASE_EDGE_URL?hallId=$_selectedHallId&key=$_selectedHallId';
  }

  Widget _buildCopyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Icon(icon, color: primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: textDark, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ $label'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy, color: primary, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _saveIntegration,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('حفظ إعدادات الربط',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_apiUrlCtrl.text.trim().isEmpty) {
      setState(() {
        _testResult = 'الرجاء إدخال رابط الـ API';
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final uri = Uri.tryParse(_apiUrlCtrl.text.trim());
      if (uri == null || !uri.isAbsolute) {
        throw Exception('الرابط غير صالح');
      }

      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _testing = false;
        _testResult = '✅ الرابط صالح. سيتم اختبار الاتصال الفعلي عند أول حجز.';
        _testSuccess = true;
      });
    } catch (e) {
      setState(() {
        _testing = false;
        _testResult = '❌ فشل الاختبار: $e';
        _testSuccess = false;
      });
    }
  }

  Future<void> _saveIntegration() async {
    if (_selectedHallId == null) {
      _showError('الرجاء اختيار القاعة');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('halls')
          .doc(_selectedHallId)
          .set({
        'integration': {
          'apiUrl': _apiUrlCtrl.text.trim(),
          'apiKey': _apiKeyCtrl.text.trim(),
          'isEnabled': _isEnabled,
          'webhookSecret': _selectedHallId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('تم الحفظ!', style: TextStyle(color: textDark, fontSize: 18)),
            ],
          ),
          content: const Text(
            'تم حفظ إعدادات الربط بنجاح.',
            style: TextStyle(color: textDark, fontSize: 14, height: 1.6),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('فشل الحفظ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: textLight, fontSize: 11, height: 1.5)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}
