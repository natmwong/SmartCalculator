import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  await dotenv.load();
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Calculator',
      theme: ThemeData.dark(),
      home: CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  CalculatorScreenState createState() => CalculatorScreenState();
}

class CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '';
  bool _isScientific = false;
  bool _isLoading = false;

  final List<String> _basicButtons = [
    '(',
    ')',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '-',
    '1',
    '2',
    '3',
    '+',
    '0',
    '.',
    '⌫',
    '=',
  ];

  final List<String> _advancedButtons = [
    'sin',
    'cos',
    'tan',
    'log',
    'ln',
    '^',
    'π',
    'e',
    '√',
  ];

  void _handleButtonPress(String text) {
    setState(() {
      if (text == '=') {
        _evaluateExpression();
      } else if (text == 'C') {
        _expression = '';
        _result = '';
      } else if (text == '⌫') {
        _expression =
            _expression.isNotEmpty
                ? _expression.substring(0, _expression.length - 1)
                : '';
      } else if (text == '()') {
        _expression += '()';
      } else {
        _expression += text;
      }
    });
  }

  Future<void> _evaluateExpression() async {
    if (_expression.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY']}',
          'HTTP-Referer': 'YOUR_APP_URL', // Required by OpenRouter
          'X-Title': 'Calculator',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-chat-v3-0324:free',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a calculator. 
            Evaluate the expression. Use degrees for trigonometry.
            Return ONLY integers, unless the numerical result requires decimals,
            then return ONLY numerical values rounded to 5 decimals.
            No explanations are needed, only a numerical value.
            If invalid, return "Error: [description]"''',
            },
            {'role': 'user', 'content': _expression},
          ],
          'temperature': 0,
        }),
      );

      final data = jsonDecode(response.body);

      // Debug print to inspect full response
      print('API Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'API Error: ${data['error']?['message'] ?? response.body}',
        );
      }

      if (data['choices'] == null || data['choices'].isEmpty) {
        throw Exception('Invalid response structure');
      }

      final result = data['choices'][0]['message']['content'].trim();

      setState(() {
        _result = result.startsWith('Error:') ? result : '= $result';
      });
    } catch (e) {
      setState(
        () => _result = 'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildButton(String text) {
    final Set<String> operationButtons = {
      '+',
      '-',
      '×',
      '÷',
      '⌫',
      '(',
      ')',
      '.',
      'sin',
      'cos',
      'tan',
      'log',
      'ln',
      '^',
      'π',
      'e',
      '√',
    };

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => _handleButtonPress(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: text == '=' ? Color(0xFF379058) : Color(0xFF282828),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                text == 'C'
                    ? Color(0xFFB93623)
                    : operationButtons.contains(text)
                    ? Color(0xFF6DAB7F)
                    : Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        title: const Text('Calculator', style: TextStyle(color: Colors.white)),
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.calculate, color: Color(0xFF539E6C)),
              ),
              Switch(
                value: _isScientific,
                onChanged: (value) => setState(() => _isScientific = value),
                activeTrackColor: Color(0xFF9EC7A8),
                activeColor: Color(0xFF539E6C),
                inactiveThumbColor: Color(0xFF9EC7A8),
                trackOutlineColor: WidgetStateProperty.all(Color(0xFF9EC7A8)),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Color(0xFF121212),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_expression, style: TextStyle(fontSize: 24)),
                  SizedBox(height: 10),
                  _isLoading
                      ? Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                      : Text(
                        _result,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: [
                  _buildButton('C'), // Always add the "C" button first
                  if (_isScientific)
                    ..._advancedButtons.map(
                      _buildButton,
                    ), // Add scientific buttons if enabled
                  ..._basicButtons
                      .where((button) => button != 'C')
                      .map(_buildButton),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
