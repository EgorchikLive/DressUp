import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dress_up/models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;

  const SettingsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    // _phoneController.text = widget.user.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Основная информация'),
          _buildTextField(_nameController, 'Имя', Icons.person),
          _buildTextField(_emailController, 'Email', Icons.email, enabled: false),
          _buildTextField(_phoneController, 'Телефон', Icons.phone),
          
          SizedBox(height: 24),
          _buildSectionHeader('Уведомления'),
          _buildSwitchOption(
            'Уведомления',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          if (_notificationsEnabled) ...[
            _buildSwitchOption(
              'Email уведомления',
              _emailNotifications,
              (value) => setState(() => _emailNotifications = value),
            ),
            _buildSwitchOption(
              'Push уведомления',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
          ],
          
          SizedBox(height: 24),
          _buildSectionHeader('Приложение'),
          _buildListTile('О приложении', Icons.info, () {}),
          _buildListTile('Политика конфиденциальности', Icons.privacy_tip, () {}),
          _buildListTile('Условия использования', Icons.description, () {}),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _saveSettings() async {
    if (_nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'notifications': {
          'enabled': _notificationsEnabled,
          'email': _emailNotifications,
          'push': _pushNotifications,
        },
        'updatedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Настройки сохранены')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}