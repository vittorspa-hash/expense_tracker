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
- **Autenticazione Firebase** (login / registrazione)
- **Gestione spese**: aggiunta, modifica e cancellazione delle spese
- **Resoconti**:
  - DaysPage → riepilogo giornaliero
  - MonthsPage → riepilogo mensile
  - YearsPage → riepilogo annuale con grafico 
- **Pagine principali**:
  - AuthPage → login e registrazione
  - HomePage → overview delle spese recenti
  - ProfilePage → informazioni utente
  - SettingsPage → impostazioni app, notifiche, limiti di spesa
- **Notifiche locali**:
  - Giornaliera
  - Superamento limite spesa
- **Dark Mode** e layout adattivo con supporto a Cupertino/Material
- **Responsive Layout** con `flutter_screenutil`

---

## 🧱 Stack Tecnologico
- **Framework:** Flutter & Dart  
- **State Management:** GetX, Provider  
- **Database:** Firebase Firestore  
- **Autenticazione:** Firebase Auth  
- **Notifiche:** `flutter_local_notifications`  
- **Gestione layout responsive:** `flutter_screenutil`  
- **Grafici:** `fl_chart`  
- **Localizzazione:** `intl`  

---

## ⚡ Screenshot
**Login Page**  
![Login Page](assets/screenshots/auth_page.png)

**Home Page**  
![Home Page](assets/screenshots/home_page.png)

**Years Page**  
![Years Page Graph](assets/screenshots/years_page.png)

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

## 🗂️ Struttura del progetto
- `lib/components/` → Widget riutilizzabili
- `lib/controllers/` → Controller GetX per selezione multipla
- `lib/models/` → Modelli dati
- `lib/pages/` → Pagine dell'app
- `lib/providers/` → Provider per settings e tema
- `lib/repositories/` → Gestione dati Firebase
- `lib/services/` → Service per notifiche
- `lib/theme/` → Color palette e tema
- `lib/utils/` → Utils per animazioni e snackbar
- `lib/firebase_options.dart` → Configurazione Firebase pubblica

---

## 📝 Note importanti
- `firebase_options.dart` è incluso e contiene solo **chiavi pubbliche** Firebase; non rappresenta un rischio di sicurezza.
- I file sensibili `GoogleService-Info.plist` e `google-services.json` **non sono tracciati su GitHub**.

---

## 📄 Licenza
MIT License © Vittorio Spagnuolo