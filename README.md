# Expense Tracker

![License](https://img.shields.io/badge/license-MIT-green)

**Expense Tracker** è un'app mobile Flutter per la gestione delle spese personali.  
Permette di creare e tenere traccia delle spese, con statistiche giornaliere, mensili e annuali, 
supporto a notifiche, dark mode, localizzazione completa (IT, EN, FR, ES, DE, PT) e un sistema multi-valuta intelligente con tassi di cambio storici.

---

## 🎯 Obiettivi del progetto
- Monitorare le spese personali in modo semplice e veloce.
- Visualizzare resoconti giornalieri, mensili e annuali.
- Inviare notifiche giornaliere e avvisi di superamento limite spesa.
- Offrire un'esperienza responsive e adaptive su dispositivi mobili.
- Supportare autenticazione sicura tramite Firebase.
- Garantire accessibilità internazionale tramite supporto multilingua e multivaluta.

---

## 📱 Funzionalità principali
- **Autenticazione Firebase** (Login / Registrazione)
- **Gestione spese**: Aggiunta, modifica e cancellazione delle spese
- **Supporto Multilingua**:
  - Rilevamento automatico della lingua del dispositivo
  - Traduzione completa in:
    - 🇮🇹 Italiano (`it`)
    - 🇺🇸 Inglese (`en`)
    - 🇫🇷 Francese (`fr`)
    - 🇪🇸 Spagnolo (`es`)
    - 🇩🇪 Tedesco (`de`)
    - 🇵🇹 Portoghese (`pt`)
- **Multi-Valuta Smart**: 
  - Supporto per valute:
    - EUR (€),
    - USD ($),
    - GBP (£),
    - JPY (¥).
  - Conversione in tempo reale basata su API (Frankfurter).
- **Resoconti**:
  - DaysPage → Riepilogo giornaliero
  - MonthsPage → Riepilogo mensile
  - YearsPage → Riepilogo annuale con grafico 
- **Pagine principali**:
  - AuthPage → Login e registrazione
  - HomePage → Overview delle spese recenti
  - ProfilePage → Informazioni utente
  - SettingsPage → Impostazioni app (Tema, Notifiche, Lingua, Valuta)
- **Notifiche locali**:
  - Giornaliera
  - Superamento limite spesa
- **Dark Mode** e **Adaptive Layout** con supporto a Cupertino/Material
- **Responsive Layout** con `flutter_screenutil`

---

## 🌟 Feature Spotlight: Smart Multi-Currency System
Il sistema di gestione valute è progettato per essere resiliente e garantire la coerenza dei dati storici:

1. **Snapshot dei Tassi Storici:** Al momento della creazione di una spesa, vengono scaricati e salvati i tassi di cambio attuali. 
Questo garantisce che una spesa di 100$ fatta 6 mesi fa mantenga il suo valore storico in € di quel giorno, non quello di oggi.
2. **Offline Resilience (Soft Fail):** Se l'utente è offline durante la creazione, l'app tenta prima di recuperare i tassi dalla cache locale. 
Se anche questa è vuota, non blocca l'operazione ma salva la spesa con un tasso fallback (1:1), segnalando visivamente l'anomalia tramite un'icona di warning.
3. **Self-Healing (Smart Update):** Il sistema implementa una logica di auto-riparazione. Se l'utente modifica una spesa "offline" quando la connessione è tornata disponibile, 
il sistema scarica automaticamente i tassi mancanti, aggiorna il database e rimuove il warning.
4. **Strategia di Caching:** Utilizzo del pattern Network-First, Cache-Fallback per garantire velocità e funzionamento anche con connettività instabile.

---

## ⚡ Screenshot
**Auth Page**  
![Auth Page](assets/screenshots/auth_page2.png)

**Home Page**  
![Home Page](assets/screenshots/home_page3.png)

**Years Page**  
![Years Page Graph](assets/screenshots/years_page2.png)

---

## 🗂️ Struttura del progetto
- `lib/main.dart` → Entry Point: Configurazione ambiente, inizializzazione Firebase, Dependency Injection (GetIt) e iniezione dei MultiProvider
- `lib/app.dart` → App Configuration: Tema, localizzazione, routing e gestione lifecycle
- `lib/components/` →  Widget UI riutilizzabili divisi per contesto
- `lib/l10n/` →  File di configurazione per la localizzazione (.arb) e stringhe tradotte
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
- **Networking:** `http` (API Frankfurter per tassi di cambio)
- **Notifications:** `flutter_local_notifications`  
- **Charts:** `fl_chart`  
- **Internationalization:** `flutter_localizations`, `intl`
- **Utilities:** `uuid` (ID univoci), `shared_preferences` (Cache locale)

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