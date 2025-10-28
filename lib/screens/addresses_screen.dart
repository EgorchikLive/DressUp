import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddressesScreen extends StatefulWidget {
  final String userId;

  const AddressesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Адреса доставки'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddAddressDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final addresses = snapshot.data?.docs ?? [];

          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Адресов нет',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте адрес доставки',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index].data() as Map<String, dynamic>;
              return _buildAddressCard(address, addresses[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address, String addressId) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.location_on, color: Colors.blue),
        title: Text(address['address'] ?? ''),
        subtitle: Text('${address['city'] ?? ''}, ${address['zipCode'] ?? ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () => _showEditAddressDialog(context, address, addressId),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteAddress(addressId),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить адрес'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Адрес'),
              ),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'Город'),
              ),
              TextField(
                controller: _zipCodeController,
                decoration: InputDecoration(labelText: 'Почтовый индекс'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => _addAddress(context),
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAddressDialog(BuildContext context, Map<String, dynamic> address, String addressId) {
    _addressController.text = address['address'] ?? '';
    _cityController.text = address['city'] ?? '';
    _zipCodeController.text = address['zipCode'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать адрес'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Адрес'),
              ),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'Город'),
              ),
              TextField(
                controller: _zipCodeController,
                decoration: InputDecoration(labelText: 'Почтовый индекс'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => _updateAddress(context, addressId),
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _addAddress(BuildContext context) async {
    if (_addressController.text.isNotEmpty && _cityController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('addresses')
          .add({
        'address': _addressController.text,
        'city': _cityController.text,
        'zipCode': _zipCodeController.text,
        'createdAt': DateTime.now(),
      });

      _clearControllers();
      Navigator.pop(context);
    }
  }

  void _updateAddress(BuildContext context, String addressId) async {
    if (_addressController.text.isNotEmpty && _cityController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('addresses')
          .doc(addressId)
          .update({
        'address': _addressController.text,
        'city': _cityController.text,
        'zipCode': _zipCodeController.text,
        'updatedAt': DateTime.now(),
      });

      _clearControllers();
      Navigator.pop(context);
    }
  }

  void _deleteAddress(String addressId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  void _clearControllers() {
    _addressController.clear();
    _cityController.clear();
    _zipCodeController.clear();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }
}