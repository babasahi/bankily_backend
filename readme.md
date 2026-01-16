# Bankily Clone Backend API

A simple FastAPI backend for a mobile banking application, designed for educational purposes.

## Features

- ✅ User Registration & Authentication (JWT)
- 💸 Send Money Between Users
- 💰 Check Account Balance
- 📊 Transaction History
- 🏦 Admin Dashboard for Cash Deposits

## Installation

### 1. Install Python

Make sure you have Python 3.8+ installed on your laptop.

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

Or install individually:

```bash
pip install fastapi uvicorn pyjwt pydantic[email] python-multipart
```

## Running Locally

### Start the API Server

```bash
python main.py
```

The API will be available at:

- API: http://localhost:8000
- API Documentation: http://localhost:8000/docs

### Open the Admin Dashboard

Simply open `admin_dashboard.html` in your web browser.

## Making it Accessible to Students Over the Internet

### Option 1: Using ngrok (Easiest - Recommended for Bootcamp)

1. **Download ngrok**: Go to https://ngrok.com/download
2. **Sign up** for a free account to get an authtoken
3. **Install ngrok** and authenticate:
   ```bash
   ngrok config add-authtoken YOUR_AUTH_TOKEN
   ```
4. **Start your FastAPI server** (if not already running):
   ```bash
   python main.py
   ```
5. **In a new terminal, run ngrok**:
   ```bash
   ngrok http 8000
   ```
6. **Share the URL** - ngrok will give you a public URL like:

   ```
   https://abc123.ngrok.io
   ```

   Share this URL with your students!

7. **Update the admin dashboard**: Open `admin_dashboard.html` and change line 278:
   ```javascript
   const API_URL = "https://your-ngrok-url.ngrok.io";
   ```

### Option 2: Using Your Local Network (WiFi)

If all students are on the same WiFi network:

1. **Find your laptop's IP address**:
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr`
   - Example: `192.168.1.100`

2. **Make sure your firewall allows connections** on port 8000

3. **Students connect using**: `http://YOUR_IP:8000`
   - Example: `http://192.168.1.100:8000`

### Option 3: Deploy to a Cloud Server (Production)

For a more permanent solution:

- **Heroku** (Free tier available)
- **Railway** (Easy deployment)
- **DigitalOcean** ($5/month)
- **AWS/Google Cloud** (Free tier available)

## API Endpoints

### Authentication

**POST** `/auth/register`

```json
{
  "email": "user@example.com",
  "password": "password123",
  "full_name": "John Doe",
  "phone": "+1234567890"
}
```

**POST** `/auth/login`

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### Account

**GET** `/account/balance`

- Requires: `Authorization: Bearer YOUR_TOKEN`

### Transactions

**POST** `/transactions/send`

```json
{
  "recipient_email": "recipient@example.com",
  "amount": 100.5,
  "note": "Payment for lunch"
}
```

- Requires: `Authorization: Bearer YOUR_TOKEN`

**GET** `/transactions/history`

- Requires: `Authorization: Bearer YOUR_TOKEN`

### Admin Endpoints

**POST** `/admin/deposit`

```json
{
  "user_email": "user@example.com",
  "amount": 500.0,
  "note": "Cash deposit"
}
```

**GET** `/admin/users`

- Returns all users and their balances

## Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BankilyAPI {
  static const String baseUrl = 'http://YOUR_NGROK_URL'; // Change this!

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get Balance
  static Future<Map<String, dynamic>> getBalance(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/account/balance'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  // Send Money
  static Future<Map<String, dynamic>> sendMoney(
    String token, String recipientEmail, double amount, String note
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/send'),
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
    return jsonDecode(response.body);
  }
}
```

## Testing the API

### Using the Interactive Documentation

Visit `http://localhost:8000/docs` (or your ngrok URL + `/docs`) to test all endpoints interactively.

### Using curl

```bash
# Register a user
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","full_name":"Test User","phone":"1234567890"}'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Check balance (replace YOUR_TOKEN)
curl -X GET http://localhost:8000/account/balance \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Important Notes for Bootcamp

1. **Data is in-memory**: All data is lost when you restart the server. This is intentional for learning purposes.

2. **Security**: This is a simplified version for learning. In production:
   - Use a real database (PostgreSQL, MySQL)
   - Use environment variables for secrets
   - Add input validation
   - Implement rate limiting
   - Use HTTPS

3. **Admin Dashboard**: No authentication required - only use in trusted environments!

4. **Token Expiration**: Tokens expire after 7 days

## Troubleshooting

### Port 8000 already in use

```bash
# Find and kill the process
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Mac/Linux
lsof -ti:8000 | xargs kill -9
```

### Students can't connect

- Check firewall settings
- Make sure you're on the same network (for local network option)
- Verify ngrok is running (for ngrok option)
- Check the URL in the Flutter app matches your backend URL

### CORS errors

- The API already has CORS enabled for all origins
- If issues persist, check browser console for exact error

## Support

For questions during the bootcamp, check:

1. API Documentation: `http://your-url/docs`
2. Make sure the server is running
3. Check network connectivity
4. Verify URLs are correct in Flutter app

## License

MIT License - Free for educational use
