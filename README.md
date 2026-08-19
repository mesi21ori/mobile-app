# የሰንበት ትምህርት ቤት ንብረትና አልባሳት መቆጣጠሪያ

Full-stack Amharic mobile app:

- **Mobile:** Flutter (Android, iOS, web)
- **API:** NestJS
- **Database:** Neon PostgreSQL (shared by all users)

The phone never connects to Postgres. Everyone uses the same Neon database through the API.

## First-time setup

### 1. Backend

```bash
cd backend
npm install
npx prisma db push
npx prisma db seed
npm run start:dev
```

API: `http://localhost:3000/api/health`

Default Super Admin:

- Username: `admin`
- Password: `Admin@123`

Change this password after first login.

`backend/.env` holds `DATABASE_URL` and `DIRECT_URL`. Do not commit it.

### 2. Flutter app

```bash
cd mobile
flutter pub get
flutter run
```

- Android emulator: API is `http://10.0.2.2:3000/api`
- Windows / web / iOS simulator: `http://127.0.0.1:3000/api`
- Physical phone: on the login screen open **የሰርቨር አድራሻ** and use `http://YOUR_PC_LAN_IP:3000/api` (same Wi‑Fi)

## Modules

1. ልብሰ ስብሐት — events, groups, issue/return, dirty list, late penalty
2. ንብረት — returnable vs consumable, checkout, damaged/lost
3. ፋይናንስ — income, expense, net balance
4. ኦዲት — 3 or 6 month department count, Super Admin approval
5. ተጠቃሚዎች — Super Admin / Admin / User

## Roles

| Role | Amharic | Access |
|---|---|---|
| SUPER_ADMIN | ዋና አስተዳዳሪ | Everything + users + audit approval |
| ADMIN | አስተዳዳሪ | Daily operations + create audits |
| USER | ተጠቃሚ | View only |
