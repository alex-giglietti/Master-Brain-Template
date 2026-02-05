# Telegram Bot Setup Guide

> Complete instructions for setting up and configuring Telegram bots

## Creating Your Bot

### Step 1: Create Bot with BotFather

1. Open Telegram app
2. Search for `@BotFather`
3. Start a conversation and send `/newbot`
4. Follow the prompts:
   - Enter a **display name** for your bot (e.g., "Company Name Assistant")
   - Enter a **username** (must end in 'bot', e.g., "companynamebot")
5. Save the **API token** provided (format: `123456789:ABCdefGHIjklmNOPQRstUVwxyz`)

### Step 2: Configure Bot Settings

Send these commands to @BotFather:

```
/setdescription
```
Enter: "AI assistant for [Company Name]. Get instant answers about our services, schedule calls, and more."

```
/setabouttext
```
Enter: "Official AI assistant for [Company Name]. Available 24/7 to help you."

```
/setuserpic
```
Upload your company logo or bot avatar.

```
/setcommands
```
Enter:
```
start - Start a conversation
help - Get help using this bot
services - Learn about our services
contact - Speak to a human
schedule - Book a meeting
```

### Step 3: Enable Inline Mode (Optional)

```
/setinline
```
Enter a placeholder text: "Search for information..."

This allows users to use your bot inline in any chat by typing `@yourbotname query`.

## Bot Token Security

**IMPORTANT:** Never share or commit your bot token.

### Secure Storage
- Store in environment variables
- Use secrets manager in production
- Rotate if compromised

### If Token is Compromised
1. Go to @BotFather
2. Send `/revoke`
3. Select your bot
4. Update your application with new token

## Webhook vs. Polling

### Polling (Development)
Bot regularly checks for updates.

```python
# Simple polling setup
import telebot

bot = telebot.TeleBot(TOKEN)

@bot.message_handler(commands=['start'])
def send_welcome(message):
    bot.reply_to(message, "Welcome!")

bot.polling()
```

### Webhook (Production)
Telegram pushes updates to your server.

```python
# Webhook setup
from flask import Flask, request
import telebot

app = Flask(__name__)
bot = telebot.TeleBot(TOKEN)

@app.route(f'/{TOKEN}', methods=['POST'])
def webhook():
    update = telebot.types.Update.de_json(request.stream.read().decode('utf-8'))
    bot.process_new_updates([update])
    return '', 200

# Set webhook
bot.remove_webhook()
bot.set_webhook(url=f'https://yourdomain.com/{TOKEN}')
```

## Message Types

### Text Messages
```python
@bot.message_handler(content_types=['text'])
def handle_text(message):
    # Process text message
    pass
```

### Commands
```python
@bot.message_handler(commands=['start', 'help'])
def handle_commands(message):
    if message.text == '/start':
        # Send welcome
        pass
    elif message.text == '/help':
        # Send help
        pass
```

### Callbacks (Button Clicks)
```python
@bot.callback_query_handler(func=lambda call: True)
def handle_callback(call):
    if call.data == 'option1':
        # Handle option 1
        pass
```

## Interactive Elements

### Inline Keyboards
```python
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton

markup = InlineKeyboardMarkup()
markup.add(
    InlineKeyboardButton("Option 1", callback_data="opt1"),
    InlineKeyboardButton("Option 2", callback_data="opt2")
)

bot.send_message(chat_id, "Choose an option:", reply_markup=markup)
```

### Reply Keyboards
```python
from telebot.types import ReplyKeyboardMarkup, KeyboardButton

markup = ReplyKeyboardMarkup(resize_keyboard=True)
markup.add(
    KeyboardButton("Services"),
    KeyboardButton("Contact Us")
)

bot.send_message(chat_id, "How can I help?", reply_markup=markup)
```

## Group Chat Setup

### Add Bot to Group
1. Add bot as a member to your group
2. Make bot an admin if it needs to:
   - Delete messages
   - Pin messages
   - Manage members

### Privacy Mode
By default, bots only receive:
- Commands
- Direct replies
- Mentions

To receive all messages:
1. Go to @BotFather
2. `/setprivacy`
3. Select your bot
4. Choose "Disable"

## Channel Integration

### Posting to Channel
1. Add bot as admin to your channel
2. Get channel ID (usually @channelname or numeric ID)
3. Post messages:

```python
bot.send_message('@channelname', 'Your message here')
```

## Rate Limits

Telegram enforces these limits:
- **1 message/second** to same chat
- **30 messages/second** overall
- **20 messages/minute** to same group

Handle rate limits gracefully:
```python
import time
from telebot.apihelper import ApiTelegramException

def send_with_retry(chat_id, text, max_retries=3):
    for i in range(max_retries):
        try:
            return bot.send_message(chat_id, text)
        except ApiTelegramException as e:
            if e.error_code == 429:  # Too Many Requests
                time.sleep(e.result_json['parameters']['retry_after'])
            else:
                raise
```

## Monitoring & Analytics

### Track Bot Usage
- Log all interactions
- Monitor response times
- Track command usage
- Measure user retention

### Telegram Analytics
Use @BotAnalyticsBot or similar services to track:
- Daily active users
- Message volume
- Popular commands
- User demographics

## Troubleshooting

### Bot Not Responding
1. Verify token is correct
2. Check bot isn't blocked by user
3. Ensure webhook is properly set (if using webhooks)
4. Check server logs

### Messages Not Delivered
1. Check user hasn't blocked bot
2. Verify chat_id is correct
3. Check rate limits

### Webhook Issues
1. Ensure SSL certificate is valid
2. Verify webhook URL is accessible
3. Check server is returning 200 status

---

*See setup/openclaw.md for OpenClaw-specific Telegram configuration.*
