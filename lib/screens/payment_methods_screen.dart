import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String userId;

  const PaymentMethodsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Способы оплаты'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddCardDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('paymentMethods')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final paymentMethods = snapshot.data?.docs ?? [];

          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Способы оплаты не добавлены',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте карту для быстрой оплаты',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: paymentMethods.length,
            itemBuilder: (context, index) {
              final method = paymentMethods[index].data() as Map<String, dynamic>;
              return _buildPaymentMethodCard(method, paymentMethods[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, String methodId) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.credit_card, color: Colors.blue),
        title: Text('**** ${method['last4'] ?? '****'}'),
        subtitle: Text('${method['cardHolder'] ?? ''} • ${method['expiry'] ?? ''}'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deletePaymentMethod(methodId),
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Добавить карту'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _cardNumberController,
                decoration: InputDecoration(labelText: 'Номер карты'),
                keyboardType: TextInputType.number,
                maxLength: 16,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: InputDecoration(labelText: 'ММ/ГГ'),
                      maxLength: 5,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      decoration: InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _cardHolderController,
                decoration: InputDecoration(labelText: 'Имя держателя карты'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () => _addCard(context),
              child: Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _addCard(BuildContext context) async {
    if (_cardNumberController.text.length == 16 &&
        _expiryController.text.isNotEmpty &&
        _cvvController.text.length == 3 &&
        _cardHolderController.text.isNotEmpty) {
      
      final last4 = _cardNumberController.text.substring(12);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('paymentMethods')
          .add({
        'last4': last4,
        'expiry': _expiryController.text,
        'cardHolder': _cardHolderController.text,
        'createdAt': DateTime.now(),
      });

      _clearControllers();
      Navigator.pop(context);
    }
  }

  void _deletePaymentMethod(String methodId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('paymentMethods')
        .doc(methodId)
        .delete();
  }

  void _clearControllers() {
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardHolderController.clear();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }
}