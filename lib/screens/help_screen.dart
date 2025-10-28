import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Помощь'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildHelpItem(
            'Как оформить заказ?',
            'Выберите товары, добавьте их в корзину, перейдите в корзину и нажмите "Оформить заказ".',
          ),
          _buildHelpItem(
            'Как отследить заказ?',
            'В разделе "Мои заказы" вы можете увидеть статус вашего заказа и номер отслеживания.',
          ),
          _buildHelpItem(
            'Как вернуть товар?',
            'Возврат возможен в течение 14 дней с момента получения заказа. Обратитесь в службу поддержки.',
          ),
          _buildHelpItem(
            'Способы оплаты',
            'Мы принимаем банковские карты, электронные кошельки и наличные при получении.',
          ),
          _buildHelpItem(
            'Доставка',
            'Доставка осуществляется курьерской службой. Срок доставки 1-3 рабочих дня.',
          ),
          _buildHelpItem(
            'Контакты службы поддержки',
            'Телефон: +7 (999) 123-45-67\nEmail: support@dressup.ru\nВремя работы: 9:00-21:00',
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}