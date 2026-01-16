// FLUTTER INTEGRATION EXAMPLE
// Add this to your Flutter project's pubspec.yaml:
// dependencies:
//   http: ^1.1.0

import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================
// CHANGE THIS URL TO YOUR BACKEND URL
// ============================================
const String API_BASE_URL = 'http://localhost:8000';
// For ngrok: 'https://your-ngrok-url.ngrok.io'
// For local network: 'http://192.168.1.XXX:8000'

class BankilyAPI {
  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Get account balance
  static Future<Map<String, dynamic>> getBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/account/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      throw Exception('Failed to get balance: $e');
    }
  }

  // Send money
  static Future<Map<String, dynamic>> sendMoney({
    required String token,
    required String recipientEmail,
    required double amount,
    String note = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$API_BASE_URL/transactions/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipient_email': recipientEmail,
          'amount': amount,
          'note': note,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      throw Exception('Failed to send money: $e');
    }
  }

  // Get transaction history
  static Future<List<dynamic>> getTransactionHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/transactions/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transactions'] as List<dynamic>;
      } else {
        throw Exception(jsonDecode(response.body)['detail']);
      }
    } catch (e) {
      throw Exception('Failed to get transaction history: $e');
    }
  }
}

// ============================================
// USAGE EXAMPLES
// ============================================

// Example 1: Register a new user
void exampleRegister() async {
  try {
    final result = await BankilyAPI.register(
      email: 'john@example.com',
      password: 'password123',
      fullName: 'John Doe',
      phone: '+1234567890',
    );

    print('Registration successful!');
    print('Token: ${result['token']}');
    print('User: ${result['user']}');

    // Save the token for future requests
    // Example: await storage.write(key: 'token', value: result['token']);
  } catch (e) {
    print('Error: $e');
  }
}

// Example 2: Login
void exampleLogin() async {
  try {
    final result = await BankilyAPI.login(
      email: 'john@example.com',
      password: 'password123',
    );

    print('Login successful!');
    print('Token: ${result['token']}');
    print('Balance: ${result['user']['balance']}');

    // Save the token
    // await storage.write(key: 'token', value: result['token']);
  } catch (e) {
    print('Error: $e');
  }
}

// Example 3: Check balance
void exampleCheckBalance() async {
  try {
    String token = 'YOUR_SAVED_TOKEN'; // Get from storage

    final result = await BankilyAPI.getBalance(token);

    print('Balance: ${result['balance']}');
    print('User: ${result['full_name']}');
  } catch (e) {
    print('Error: $e');
  }
}

// Example 4: Send money
void exampleSendMoney() async {
  try {
    String token = 'YOUR_SAVED_TOKEN'; // Get from storage

    final result = await BankilyAPI.sendMoney(
      token: token,
      recipientEmail: 'jane@example.com',
      amount: 50.0,
      note: 'Lunch payment',
    );

    print('Money sent successfully!');
    print('Transaction ID: ${result['transaction']['id']}');
    print('New balance: ${result['new_balance']}');
  } catch (e) {
    print('Error: $e');
  }
}

// Example 5: Get transaction history
void exampleTransactionHistory() async {
  try {
    String token = 'YOUR_SAVED_TOKEN'; // Get from storage

    final transactions = await BankilyAPI.getTransactionHistory(token);

    print('Transaction history:');
    for (var transaction in transactions) {
      print(
        '- ${transaction['type']}: ${transaction['amount']} (${transaction['timestamp']})',
      );
    }
  } catch (e) {
    print('Error: $e');
  }
}

// ============================================
// COMPLETE LOGIN SCREEN EXAMPLE
// ============================================

/*
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final result = await BankilyAPI.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Save token (use flutter_secure_storage or shared_preferences)
      // await storage.write(key: 'token', value: result['token']);

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome back, ${result['user']['full_name']}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bankily Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
*/
