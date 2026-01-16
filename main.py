from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional, Dict
import jwt
import hashlib
from datetime import datetime, timedelta
from decimal import Decimal
import json

app = FastAPI(title="Bankily Clone API")

# CORS middleware to allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple in-memory database (replace with real DB in production)
users_db: Dict[str, dict] = {}
transactions_db: list = []

# Security
SECRET_KEY = "your-secret-key-change-in-production"
security = HTTPBearer()

# Models
class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    phone: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class SendMoney(BaseModel):
    recipient_email: str
    amount: float
    note: Optional[str] = ""

class Deposit(BaseModel):
    user_email: str
    amount: float
    note: Optional[str] = "Cash deposit"

# Helper functions
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def create_token(email: str) -> str:
    payload = {
        "email": email,
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=["HS256"])
        return payload["email"]
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Endpoints
@app.get("/")
def read_root():
    return {"message": "Bankily Clone API", "status": "running"}

@app.post("/auth/register")
def register(user: UserRegister):
    if user.email in users_db:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    users_db[user.email] = {
        "email": user.email,
        "password": hash_password(user.password),
        "full_name": user.full_name,
        "phone": user.phone,
        "balance": 0.0,
        "created_at": datetime.utcnow().isoformat()
    }
    
    token = create_token(user.email)
    
    return {
        "message": "User registered successfully",
        "token": token,
        "user": {
            "email": user.email,
            "full_name": user.full_name,
            "phone": user.phone,
            "balance": 0.0
        }
    }

@app.post("/auth/login")
def login(user: UserLogin):
    if user.email not in users_db:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    stored_user = users_db[user.email]
    if stored_user["password"] != hash_password(user.password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    token = create_token(user.email)
    
    return {
        "message": "Login successful",
        "token": token,
        "user": {
            "email": stored_user["email"],
            "full_name": stored_user["full_name"],
            "phone": stored_user["phone"],
            "balance": stored_user["balance"]
        }
    }

@app.get("/account/balance")
def get_balance(email: str = Depends(verify_token)):
    if email not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    
    user = users_db[email]
    return {
        "balance": user["balance"],
        "email": user["email"],
        "full_name": user["full_name"]
    }

@app.post("/transactions/send")
def send_money(transaction: SendMoney, sender_email: str = Depends(verify_token)):
    # Validate sender
    if sender_email not in users_db:
        raise HTTPException(status_code=404, detail="Sender not found")
    
    # Validate recipient
    if transaction.recipient_email not in users_db:
        raise HTTPException(status_code=404, detail="Recipient not found")
    
    # Check if sending to self
    if sender_email == transaction.recipient_email:
        raise HTTPException(status_code=400, detail="Cannot send money to yourself")
    
    # Validate amount
    if transaction.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    
    # Check balance
    sender = users_db[sender_email]
    if sender["balance"] < transaction.amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")
    
    # Process transaction
    recipient = users_db[transaction.recipient_email]
    sender["balance"] -= transaction.amount
    recipient["balance"] += transaction.amount
    
    # Record transaction
    transaction_record = {
        "id": len(transactions_db) + 1,
        "sender": sender_email,
        "recipient": transaction.recipient_email,
        "amount": transaction.amount,
        "note": transaction.note,
        "timestamp": datetime.utcnow().isoformat(),
        "type": "transfer"
    }
    transactions_db.append(transaction_record)
    
    return {
        "message": "Money sent successfully",
        "transaction": transaction_record,
        "new_balance": sender["balance"]
    }

@app.get("/transactions/history")
def get_transaction_history(email: str = Depends(verify_token)):
    user_transactions = [
        t for t in transactions_db 
        if t["sender"] == email or t["recipient"] == email
    ]
    return {
        "transactions": user_transactions
    }

# Admin endpoint for cash deposits (for dashboard)
@app.post("/admin/deposit")
def admin_deposit(deposit: Deposit):
    if deposit.user_email not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    
    if deposit.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    
    user = users_db[deposit.user_email]
    user["balance"] += deposit.amount
    
    # Record transaction
    transaction_record = {
        "id": len(transactions_db) + 1,
        "sender": "ADMIN_DEPOSIT",
        "recipient": deposit.user_email,
        "amount": deposit.amount,
        "note": deposit.note,
        "timestamp": datetime.utcnow().isoformat(),
        "type": "deposit"
    }
    transactions_db.append(transaction_record)
    
    return {
        "message": "Deposit successful",
        "transaction": transaction_record,
        "new_balance": user["balance"]
    }

# Admin endpoint to get all users (for dashboard)
@app.get("/admin/users")
def get_all_users():
    users_list = []
    for email, user in users_db.items():
        users_list.append({
            "email": user["email"],
            "full_name": user["full_name"],
            "phone": user["phone"],
            "balance": user["balance"],
            "created_at": user["created_at"]
        })
    return {"users": users_list}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)