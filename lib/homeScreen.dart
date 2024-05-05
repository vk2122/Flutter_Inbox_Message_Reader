import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsQuery _query = SmsQuery();
  final List<SmsMessage> _filteredMessages = [];
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
  }

  void filterMessages(List<SmsMessage> messages) {
    _filteredMessages.clear();
    totalIncome = 0.0;
    totalExpense = 0.0;
    for (var message in messages) {
      if (message.body!.contains("Amt") ||
          message.body!.contains("Acct") ||
          message.body!.contains("Sent") ||
          message.body!.contains("Bank:") ||
          message.body!.contains("a/c") ||
          message.body!.contains("A/C")) {
        if (!message.body!.contains("will be refunded")) {
          _filteredMessages.add(message);
          double amount = double.parse(extractAmount(message.body!));
          if (extractColor(message.body!) == Colors.green) {
            totalIncome += amount;
          } else if (extractColor(message.body!) == Colors.red) {
            totalExpense += amount;
          }
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text(
                'Total Income: Rs ${totalIncome.toStringAsFixed(2)}',
              ),
              Text('Total Expense: Rs ${totalExpense.toStringAsFixed(2)}'),
              Text('Net: ${(totalIncome - totalExpense).toStringAsFixed(2)}'),
              Expanded(
                  child: _filteredMessages.isNotEmpty
                      ? ListView.builder(
                          itemCount: _filteredMessages.length,
                          itemBuilder: (context, index) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount: Rs ${extractAmount(_filteredMessages[index].body!)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: extractColor(
                                          _filteredMessages[index].body!),
                                    ),
                                  ),
                                  Text(
                                    'Sender: ${extractName(_filteredMessages[index].body!)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'Date: ${formatDate(_filteredMessages[index].date)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var permission = await Permission.sms.status;
          if (permission.isGranted) {
            final messages = await _query.querySms(
              kinds: [
                SmsQueryKind.inbox,
              ],
            );
            filterMessages(messages);
          } else {
            await Permission.sms.request();
          }
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  String extractAmount(String messageBody) {
    final matchAmount = RegExp(r'(\d{1,3}(,\d{3})*(\.\d+)?|\d+(\.\d+)?)')
        .firstMatch(messageBody);
    if (matchAmount != null) {
      return matchAmount.group(0)!;
    } else {
      return "Amount not found";
    }
  }

  Color extractColor(String messageBody) {
    if (messageBody.contains('credited') ||
        messageBody.contains('received') ||
        messageBody.contains('deposited')) {
      return Colors.green;
    } else if (messageBody.contains('debited') ||
        messageBody.contains('withdrawn') ||
        messageBody.contains('spent') ||
        messageBody.contains('Sent')) {
      return Colors.red;
    }
    return Colors.black;
  }

  String extractName(String messageBody) {
    final matchSender = RegExp(
            r'(?<=to|by(?:\sa/c\slinked\sto\sVPA)?|sender|sent\sby)\s*([^\d]+)')
        .firstMatch(messageBody.toLowerCase());
    return matchSender?.group(1) ?? "Sender not found";
  }

  String formatDate(DateTime? date) {
    if (date != null) {
      return DateFormat.yMd().add_jm().format(date);
    } else {
      return 'Date not available';
    }
  }
}
