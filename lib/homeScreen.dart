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

  @override
  void initState() {
    super.initState();
  }

  void filterMessages(List<SmsMessage> messages) {
    _filteredMessages.clear();
    for (var message in messages) {
      if (message.body!.contains("Amt") ||
          message.body!.contains("Acct") ||
          message.body!.contains("Sent") ||
          message.body!.contains("Bank:") ||
          message.body!.contains("a/c") ||
          message.body!.contains("A/C")) {
        if (!message.body!.contains("will be refunded")) {
          _filteredMessages.add(message);
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: _filteredMessages.isNotEmpty
            ? SizedBox(
                height: double.maxFinite,
                width: double.maxFinite,
                child: ListView.builder(
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
                              color:
                                  extractColor(_filteredMessages[index].body!),
                            ),
                          ),
                          Text(
                            //TODO: based on credit or debit set Sender or Reciever in below text
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
                ),
              )
            : const Center(
                child: Text('No messages found'),
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
        messageBody.contains('recieved') ||
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
