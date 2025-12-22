# Expense Tracker

![License](https://img.shields.io/badge/license-MIT-green)

**Expense Tracker** è un'app mobile Flutter per la gestione delle spese personali.  
Permette di creare e tenere traccia delle spese, con statistiche giornaliere, mensili e annuali, supporto a notifiche e dark mode.

---

## 🎯 Obiettivi del progetto
- Monitorare le spese personali in modo semplice e veloce.
- Visualizzare resoconti giornalieri, mensili e annuali.
- Inviare notifiche giornaliere e avvisi di superamento limite spesa.
- Offrire un'esperienza responsive e adaptive su dispositivi mobili.
- Supportare autenticazione sicura tramite Firebase.

---

## 📱 Funzionalità principali
- **Autenticazione Firebase** (Login / Registrazione)
- **Gestione spese**: Aggiunta, modifica e cancellazione delle spese
- **Resoconti**:
  - DaysPage → Riepilogo giornaliero
  - MonthsPage → Riepilogo mensile
  - YearsPage → Riepilogo annuale con grafico 
- **Pagine principali**:
  - AuthPage → Login e registrazione
  - HomePage → Overview delle spese recenti
  - ProfilePage → Informazioni utente
  - SettingsPage → Impostazioni app
- **Notifiche locali**:
  - Giornaliera
  - Superamento limite spesa
- **Dark Mode** e layout adattivo con supporto a Cupertino/Material
- **Responsive Layout** con `flutter_screenutil`

---

## ⚡ Screenshot
**Login Page**  
![Login Page](assets/screenshots/auth_page.png)

**Home Page**  
![Home Page](assets/screenshots/home_page.png)

**Years Page**  
![Years Page Graph](assets/screenshots/years_page.png)

---

## 🗂️ Struttura del progetto
- `lib/main.dart` → Entry Point: Configurazione ambiente, inizializzazione Firebase, Dependency Injection (GetIt) e iniezione dei MultiProvider
- `lib/app.dart` → App Configuration: Tema, localizzazione, routing e gestione lifecycle
- `lib/components/` →  Widget UI riutilizzabili divisi per contesto
- `lib/models/` → Data classes e modelli di dominio (ExpenseModel)
- `lib/pages/` → Schermate dell'applicazione
- `lib/providers/` → State Layer: Collegano la UI alla logica di business
- `lib/repositories/` → Data Layer: Accesso diretto ai dati (Firestore)
- `lib/services/` → Business Logic: Logica pura condivisa iniettata tramite GetIt
- `lib/theme/` → Definizione palette colori
- `lib/utils/` → Utilities: Motore di calcolo, sistema dialoghi adattivi, gestione snackbar e animazioni
- `lib/firebase_options.dart` → Configurazione Firebase autogenerata

---

## 🧱 Stack Tecnologico
- **Framework:** Flutter & Dart  
- **Architecture:** Layered Architecture (UI ↔ Provider ↔ Service ↔ Repository)
- **State Management:** Provider
- **Dependency Injection:** GetIt 
- **Database:** Firebase Firestore  
- **Autenticazione:** Firebase Auth  
- **UI/UX Pattern:** Adaptive Design (Material per Android, Cupertino per iOS)
- **Responsive Layout:** `flutter_screenutil`  
- **Notifications:** `flutter_local_notifications`  
- **Charts:** `fl_chart`  
- **Utilities:** `uuid` (ID univoci), `intl` (Formattazione date)

---

## 🚀 Setup e installazione
Clona il repository:
```bash
git clone https://github.com/vittorspa-hash/expense_tracker.git
cd expense_tracker
```
Installa le dipendenze Flutter:
```bash
flutter pub get
```
Configura Firebase:
- Scarica i file:
- `GoogleService-Info.plist` → iOS
- `google-services.json` → Android
- Posizionali nelle rispettive cartelle:
- `ios/Runner/`
- `android/app/`

Avvia l'app:
```bash
flutter run
```

---

## 📝 Note importanti
- `firebase_options.dart` è incluso e contiene solo **chiavi pubbliche** Firebase; non rappresenta un rischio di sicurezza.
- I file sensibili `GoogleService-Info.plist` e `google-services.json` **non sono tracciati su GitHub**.

---

## 📄 Licenza
MIT License © Vittorio Spagnuolo