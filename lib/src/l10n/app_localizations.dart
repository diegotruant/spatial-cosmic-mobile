import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _en,
    'de': _de,
    'es': _es,
    'fr': _fr,
    'it': _it,
    'pl': _pl,
    'ru': _ru,
    'ja': _ja,
    'zh': _zhCN,
    'zh_TW': _zhTW,
  };
  
  String translate(String key) {
    String langCode = locale.languageCode;
    if (locale.countryCode == 'TW') langCode = 'zh_TW';
    return _localizedValues[langCode]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
  
  // Shorthand
  String get(String key) => translate(key);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'de', 'es', 'fr', 'it', 'pl', 'ru', 'ja', 'zh'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ============== TRANSLATIONS ==============

const Map<String, String> _en = {
  // Settings
  'settings': 'Settings',
  'sport': 'Sport',
  'cycling': 'Cycling',
  'cycling_ftp': 'CYCLING FTP',
  'add_devices': 'Add devices',
  'other_options': 'Other options',
  'language': 'Language',
  'account_info': 'User account information',
  'connections': 'Connections',
  'guide': 'Guide',
  'subscription_status': 'Subscription status',
  'active': 'Active',
  'logout_reset': 'Logout/Reset',
  
  // Advanced Options
  'auto_extend_recovery': 'Enable auto-extend recovery time',
  'auto_extend_recovery_desc': 'Keep pedaling until you want to stop',
  'power_smoothing': 'Power Smoothing',
  'power_smoothing_desc': 'Smooth the power line on the graph',
  'short_press_next': 'Short Press for Next Interval',
  'short_press_next_desc': 'Allow short press to skip intervals',
  'power_match': 'Power Match',
  'power_match_desc': 'Smart trainer will match power',
  'double_sided_power': 'Double single-sided power',
  'double_sided_power_desc': 'See 1/2 of power? Turn this on',
  'disable_auto_start': 'Disable Auto-Start/Stop',
  'disable_auto_start_desc': 'Disabling requires button press',
  'vibration': 'Vibration',
  'vibration_desc': 'Haptic feedback during interaction',
  'show_power_zones': 'Show power zones',
  'show_power_zones_desc': 'Show colored indicators for zones',
  'live_workout_view': 'Live workout view',
  'live_workout_view_desc': 'Click here to copy URL',
  'sim_slope_mode': 'Sim/Slope Mode',
  'sim_slope_mode_desc': 'Specify resistance using slope angles',
  'interval_beep_type': 'Interval beep type',
  'volume_high': 'High volume',
  'volume_medium': 'Medium volume',
  'volume_low': 'Low volume',
  'silent': 'Silent',
  'hr_threshold': 'HR threshold',
  'erg_increase': 'ERG Increase %',
  'hr_increase': 'HR Increase',
  'slope_increase': 'Slope Increase %',
  'resistance_increase': 'Resistance Inc %',
  'rate_us': 'Rate us',
  'contact_feedback': 'Contact / Feedback',
  'terms_conditions': 'Terms and conditions',
  'version': 'Version',
  'delete_account': 'Delete account',
  
  // Account Info
  'username': 'Username',
  'metric_units': 'Metric units (km/kg)',
  'metric_units_desc': 'Off is miles/pounds',
  'rider_weight': 'Rider weight',
  'bike_weight': 'Bike weight',
  
  // Connections
  'connect': 'Connect',
  'disconnect': 'Disconnect',
  'strava_desc': 'This will publish completed activities to Strava.',
  'zwift_desc': '- Planned workouts on Zwift\n- Sync your TrainerDay calendar with Zwift',
  'trainingpeaks_desc': 'View and use workouts from your TrainingPeaks calendar.',
  'intervals_desc': 'Calendar sync and workout bridge. Intervals.icu sends your workouts directly to Garmin, Wahoo, and Strava.',
  'dropbox_desc': 'Upload TCX activity files to Dropbox TrainerDay folder.',
  'google_calendar_desc': 'Send training plans to Google Calendar.',
  'wahoo_desc': 'Sync workouts to your Wahoo account.',
  'garmin_desc': 'Publish workouts to your Garmin account.',
  
  // Dashboard
  'dashboard': 'Dashboard',
  'schedule': 'Schedule',
  'progress': 'Progress',
  'start_now': 'START NOW',
  'today_workout': 'Today\'s Workout',
  'athlete_profile': 'ATHLETE PROFILE',
  'metabolism': 'METABOLISM',
  'recommendation': 'RECOMMENDATION',
  'pmc_metrics': 'PMC METRICS',
  'workout_history': 'WORKOUT HISTORY',
  'weekly_tss': 'Weekly TSS',
  'fitness': 'Fitness',
  'fatigue': 'Fatigue',
  'form': 'Form',
  'estimated_ftp': 'Estimated FTP',
  
  // Workout
  'interval': 'Interval',
  'cadence': 'Cadence',
  'target': 'Target',
  'power': 'Power',
  'core_temp': 'Core Temp',
  'heart_rate': 'Heart Rate',
  'pause': 'Pause',
  'resume': 'Resume',
  'stop': 'Stop',
  'intensity': 'INTENSITY',
  
  // Common
  'save': 'Save',
  'cancel': 'Cancel',
  'close': 'Close',
  'connected': 'Connected',
  'not_connected': 'Not Connected',
  'searching': 'Searching...',
  'weekly_calendar': 'WEEKLY CALENDAR',
  'based_on_power_curve': 'Based on your Power Curve',
  'library': 'TEST',
  'workout_library': 'TEST',
  'start': 'START',
  'no_devices_found': 'No devices found. Ensure Bluetooth is on.',
  'select_device_type': 'Connect as:',
};

const Map<String, String> _it = {
  'settings': 'Impostazioni',
  'sport': 'Sport',
  'cycling': 'Ciclismo',
  'cycling_ftp': 'CYCLING FTP',
  'add_devices': 'Aggiungere dispositivi',
  'other_options': 'Altre opzioni',
  'language': 'Lingua',
  'account_info': 'Informazioni sull\'account utente',
  'connections': 'Connessioni',
  'guide': 'Guida',
  'subscription_status': 'Stato sottoscrizione',
  'active': 'Attivo',
  'logout_reset': 'Logout/Reset',
  
  'auto_extend_recovery': 'Abilita tempo di recupero autoestendi',
  'auto_extend_recovery_desc': 'Continua a pedalare fino a quando non vuoi fermarti',
  'power_smoothing': 'Livellamento Potenza',
  'power_smoothing_desc': 'Leviga linea potenza nel grafico',
  'short_press_next': 'Pressione Breve per Intervallo Successivo',
  'short_press_next_desc': 'Consenti pressione breve per saltare gli intervalli',
  'power_match': 'Power Match',
  'power_match_desc': 'L\'allenatore intelligente corrisponderà alla potenza',
  'double_sided_power': 'Doppia potenza laterale singola',
  'double_sided_power_desc': 'Vedi 1/2 della potenza? Accendi questo',
  'disable_auto_start': 'Disabilitare Auto-Start/Stop',
  'disable_auto_start_desc': 'La disabilitazione richiede la pressione del pulsante',
  'vibration': 'Vibrazione',
  'vibration_desc': 'Feedback aptico durante l\'interazione',
  'show_power_zones': 'Mostra le zone di potenza',
  'show_power_zones_desc': 'Mostra indicatori colorati per le zone',
  'live_workout_view': 'Visualizzazione allenamento in tempo reale',
  'live_workout_view_desc': 'Fare clic qui per copiare l\'URL',
  'sim_slope_mode': 'Modalità Sim/Slope',
  'sim_slope_mode_desc': 'Specifica la tua resistenza usando gli angoli di pendenza',
  'interval_beep_type': 'Tipo di beep a intervalli',
  'volume_high': 'Volume alto',
  'volume_medium': 'Volume medio',
  'volume_low': 'Volume basso',
  'silent': 'Silenzioso',
  'hr_threshold': 'HR soglia',
  'erg_increase': 'Aumento ERG %',
  'hr_increase': 'Aumento HR',
  'slope_increase': 'Aumento Slope %',
  'resistance_increase': 'Resistance Inc %',
  'rate_us': 'Valutaci',
  'contact_feedback': 'Contattaci / Feedback',
  'terms_conditions': 'Termini e condizioni',
  'version': 'Versione',
  'delete_account': 'Cancellazione dell\'account',
  
  'username': 'Nome utente',
  'metric_units': 'Unità metriche (km/kg)',
  'metric_units_desc': 'Spento è miglia/libbre',
  'rider_weight': 'Peso del pilota',
  'bike_weight': 'Peso della bicicletta',
  
  'connect': 'Collega',
  'disconnect': 'Scollega',
  'strava_desc': 'Questo pubblicherà attività completate su Strava.',
  'zwift_desc': '- Allenamenti pianificati su Zwift\n- Sincronizza il tuo calendario TrainerDay con Zwift',
  'trainingpeaks_desc': 'Vedi e utilizza gli allenamenti dal tuo calendario TrainingPeaks.',
  'intervals_desc': 'Sincronizza il calendario e invia i workout a Garmin, Wahoo e Strava usando Intervals.icu come ponte.',
  'dropbox_desc': 'Caricamento file TCX nella cartella Dropbox TrainerDay.',
  'google_calendar_desc': 'Invia piani di allenamento al Calendario di Google.',
  'wahoo_desc': 'Sincronizza allenamenti sul tuo account Wahoo.',
  'garmin_desc': 'Pubblicazione allenamenti sul tuo account Garmin.',
  
  'dashboard': 'Dashboard',
  'schedule': 'Programma',
  'progress': 'Progressi',
  'start_now': 'INIZIA ORA',
  'today_workout': 'Allenamento di Oggi',
  'athlete_profile': 'PROFILO ATLETA',
  'metabolism': 'METABOLISMO',
  'recommendation': 'RACCOMANDAZIONE',
  'pmc_metrics': 'METRICHE PMC',
  'workout_history': 'STORICO ALLENAMENTI',
  'weekly_tss': 'TSS Settimanale',
  'fitness': 'Fitness',
  'fatigue': 'Fatica',
  'form': 'Forma',
  'estimated_ftp': 'FTP Stimato',
  
  'interval': 'Intervallo',
  'cadence': 'Cadenza',
  'target': 'Target',
  'power': 'Potenza',
  'core_temp': 'Temp. Core',
  'heart_rate': 'Frequenza Cardiaca',
  'pause': 'Pausa',
  'resume': 'Riprendi',
  'stop': 'Stop',
  'intensity': 'INTENSITÀ',
  
  'save': 'Salva',
  'cancel': 'Annulla',
  'close': 'Chiudi',
  'connected': 'Connesso',
  'not_connected': 'Non Connesso',
  'searching': 'Ricerca...',
  'weekly_calendar': 'CALENDARIO SETTIMANALE',
  'based_on_power_curve': 'Basato sulla tua Power Curve',
  'library': 'TEST',
  'workout_library': 'TEST',
  'start': 'START',
  'no_devices_found': 'Nessun dispositivo trovato. Verifica il Bluetooth.',
  'select_device_type': 'Connetti come:',
};

const Map<String, String> _de = {
  'settings': 'Einstellungen',
  'sport': 'Sport',
  'cycling': 'Radfahren',
  'cycling_ftp': 'CYCLING FTP',
  'add_devices': 'Geräte hinzufügen',
  'other_options': 'Weitere Optionen',
  'language': 'Sprache',
  'account_info': 'Kontoinformationen',
  'connections': 'Verbindungen',
  'guide': 'Anleitung',
  'subscription_status': 'Abonnementstatus',
  'active': 'Aktiv',
  'logout_reset': 'Abmelden/Zurücksetzen',
  
  'auto_extend_recovery': 'Erholungszeit automatisch verlängern',
  'power_smoothing': 'Leistungsglättung',
  'vibration': 'Vibration',
  'show_power_zones': 'Leistungszonen anzeigen',
  'hr_threshold': 'HF-Schwelle',
  'erg_increase': 'ERG Erhöhung %',
  
  'username': 'Benutzername',
  'metric_units': 'Metrische Einheiten (km/kg)',
  'rider_weight': 'Fahrergewicht',
  'bike_weight': 'Fahrradgewicht',
  
  'connect': 'Verbinden',
  'disconnect': 'Trennen',
  
  'dashboard': 'Dashboard',
  'schedule': 'Zeitplan',
  'progress': 'Fortschritt',
  'start_now': 'JETZT STARTEN',
  'interval': 'Intervall',
  'cadence': 'Trittfrequenz',
  'power': 'Leistung',
  'heart_rate': 'Herzfrequenz',
  
  'save': 'Speichern',
  'cancel': 'Abbrechen',
  'connected': 'Verbunden',
  'not_connected': 'Nicht verbunden',
  'weekly_calendar': 'WOCHENKALENDER',
  'based_on_power_curve': 'Basiert auf deiner Leistungskurve',
  'library': 'Bibliothek',
  'workout_library': 'TRAINING BIBLIOTHEK',
  'start': 'START',
  'no_devices_found': 'Keine Geräte gefunden',
  'select_device_type': 'Verbinden als:',
};

const Map<String, String> _es = {
  'settings': 'Configuración',
  'sport': 'Deporte',
  'cycling': 'Ciclismo',
  'add_devices': 'Añadir dispositivos',
  'other_options': 'Otras opciones',
  'language': 'Idioma',
  'account_info': 'Información de la cuenta',
  'connections': 'Conexiones',
  'guide': 'Guía',
  'subscription_status': 'Estado de suscripción',
  'active': 'Activo',
  'logout_reset': 'Cerrar sesión/Reiniciar',
  
  'auto_extend_recovery': 'Extender tiempo de recuperación automáticamente',
  'power_smoothing': 'Suavizado de potencia',
  'vibration': 'Vibración',
  'show_power_zones': 'Mostrar zonas de potencia',
  
  'username': 'Nombre de usuario',
  'metric_units': 'Unidades métricas (km/kg)',
  'rider_weight': 'Peso del ciclista',
  'bike_weight': 'Peso de la bicicleta',
  
  'connect': 'Conectar',
  'disconnect': 'Desconectar',
  
  'dashboard': 'Panel',
  'schedule': 'Horario',
  'progress': 'Progreso',
  'start_now': 'EMPEZAR AHORA',
  'interval': 'Intervalo',
  'cadence': 'Cadencia',
  'power': 'Potencia',
  'heart_rate': 'Frecuencia cardíaca',
  
  'save': 'Guardar',
  'cancel': 'Cancelar',
  'connected': 'Conectado',
  'not_connected': 'No conectado',
  'weekly_calendar': 'CALENDARIO SEMANAL',
  'based_on_power_curve': 'Basado en tu curva de potencia',
  'library': 'Biblioteca',
  'workout_library': 'BIBLIOTECA DE ENTRENAMIENTOS',
  'start': 'INICIAR',
  'no_devices_found': 'No se encontraron dispositivos',
  'select_device_type': 'Conectar como:',
};

const Map<String, String> _fr = {
  'settings': 'Paramètres',
  'sport': 'Sport',
  'cycling': 'Cyclisme',
  'add_devices': 'Ajouter des appareils',
  'other_options': 'Autres options',
  'language': 'Langue',
  'account_info': 'Informations du compte',
  'connections': 'Connexions',
  'guide': 'Guide',
  'subscription_status': 'État de l\'abonnement',
  'active': 'Actif',
  'logout_reset': 'Déconnexion/Réinitialiser',
  
  'auto_extend_recovery': 'Prolonger automatiquement le temps de récupération',
  'power_smoothing': 'Lissage de puissance',
  'vibration': 'Vibration',
  'show_power_zones': 'Afficher les zones de puissance',
  
  'username': 'Nom d\'utilisateur',
  'metric_units': 'Unités métriques (km/kg)',
  'rider_weight': 'Poids du cycliste',
  'bike_weight': 'Poids du vélo',
  
  'connect': 'Connecter',
  'disconnect': 'Déconnecter',
  
  'dashboard': 'Tableau de bord',
  'schedule': 'Programme',
  'progress': 'Progrès',
  'start_now': 'COMMENCER',
  'interval': 'Intervalle',
  'cadence': 'Cadence',
  'power': 'Puissance',
  'heart_rate': 'Fréquence cardiaque',
  
  'save': 'Enregistrer',
  'cancel': 'Annuler',
  'connected': 'Connecté',
  'not_connected': 'Non connecté',
  'weekly_calendar': 'CALENDRIER HEBDOMADAIRE',
  'based_on_power_curve': 'Basé sur votre courbe de puissance',
  'library': 'Bibliothèque',
  'workout_library': 'BIBLIOTHÈQUE D\'ENTRAÎNEMENT',
  'start': 'DÉMARRER',
  'no_devices_found': 'Aucun appareil trouvé',
  'select_device_type': 'Connecter en tant que:',
};

const Map<String, String> _pl = {
  'settings': 'Ustawienia',
  'sport': 'Sport',
  'cycling': 'Kolarstwo',
  'add_devices': 'Dodaj urządzenia',
  'other_options': 'Inne opcje',
  'language': 'Język',
  'account_info': 'Informacje o koncie',
  'connections': 'Połączenia',
  'guide': 'Przewodnik',
  'subscription_status': 'Status subskrypcji',
  'active': 'Aktywna',
  'logout_reset': 'Wyloguj/Resetuj',
  
  'power_smoothing': 'Wygładzanie mocy',
  'vibration': 'Wibracja',
  'show_power_zones': 'Pokaż strefy mocy',
  
  'username': 'Nazwa użytkownika',
  'rider_weight': 'Waga kolarza',
  'bike_weight': 'Waga roweru',
  
  'connect': 'Połącz',
  'disconnect': 'Rozłącz',
  
  'dashboard': 'Panel',
  'schedule': 'Harmonogram',
  'progress': 'Postęp',
  'start_now': 'ZACZNIJ TERAZ',
  'interval': 'Interwał',
  'cadence': 'Kadencja',
  'power': 'Moc',
  'heart_rate': 'Tętno',
  
  'save': 'Zapisz',
  'cancel': 'Anuluj',
  'connected': 'Połączony',
  'not_connected': 'Niepołączony',
  'workout_library': 'BIBLIOTEKA TRENINGÓW',
  'start': 'START',
  'no_devices_found': 'Nie znaleziono urządzeń',
  'select_device_type': 'Połącz jako:',
};

const Map<String, String> _ru = {
  'settings': 'Настройки',
  'sport': 'Спорт',
  'cycling': 'Велоспорт',
  'add_devices': 'Добавить устройства',
  'other_options': 'Другие опции',
  'language': 'Язык',
  'account_info': 'Информация об аккаунте',
  'connections': 'Подключения',
  'guide': 'Руководство',
  'subscription_status': 'Статус подписки',
  'active': 'Активна',
  'logout_reset': 'Выход/Сброс',
  
  'power_smoothing': 'Сглаживание мощности',
  'vibration': 'Вибрация',
  'show_power_zones': 'Показать зоны мощности',
  
  'username': 'Имя пользователя',
  'rider_weight': 'Вес велосипедиста',
  'bike_weight': 'Вес велосипеда',
  
  'connect': 'Подключить',
  'disconnect': 'Отключить',
  
  'dashboard': 'Панель',
  'schedule': 'Расписание',
  'progress': 'Прогресс',
  'start_now': 'НАЧАТЬ',
  'interval': 'Интервал',
  'cadence': 'Каденс',
  'power': 'Мощность',
  'heart_rate': 'Пульс',
  
  'save': 'Сохранить',
  'cancel': 'Отмена',
  'connected': 'Подключено',
  'not_connected': 'Не подключено',
  'workout_library': 'БИБЛИОТЕКА ТРЕНИРОВОК',
  'start': 'СТАРТ',
  'no_devices_found': 'Устройства не найдены',
  'select_device_type': 'Подключить как:',
};

const Map<String, String> _ja = {
  'settings': '設定',
  'sport': 'スポーツ',
  'cycling': 'サイクリング',
  'add_devices': 'デバイスを追加',
  'other_options': 'その他のオプション',
  'language': '言語',
  'account_info': 'アカウント情報',
  'connections': '接続',
  'guide': 'ガイド',
  'subscription_status': 'サブスクリプション状態',
  'active': 'アクティブ',
  'logout_reset': 'ログアウト/リセット',
  
  'power_smoothing': 'パワースムージング',
  'vibration': '振動',
  'show_power_zones': 'パワーゾーンを表示',
  
  'username': 'ユーザー名',
  'rider_weight': 'ライダー体重',
  'bike_weight': '自転車重量',
  
  'connect': '接続',
  'disconnect': '切断',
  
  'dashboard': 'ダッシュボード',
  'schedule': 'スケジュール',
  'progress': '進捗',
  'start_now': '今すぐ開始',
  'interval': 'インターバル',
  'cadence': 'ケイデンス',
  'power': 'パワー',
  'heart_rate': '心拍数',
  
  'save': '保存',
  'cancel': 'キャンセル',
  'connected': '接続済み',
  'not_connected': '未接続',
  'workout_library': 'ワークアウトライブラリ',
  'start': '開始',
  'no_devices_found': 'デバイスが見つかりません',
  'select_device_type': '接続タイプ:',
};

const Map<String, String> _zhCN = {
  'settings': '设置',
  'sport': '运动',
  'cycling': '骑行',
  'add_devices': '添加设备',
  'other_options': '其他选项',
  'language': '语言',
  'account_info': '账户信息',
  'connections': '连接',
  'guide': '指南',
  'subscription_status': '订阅状态',
  'active': '活跃',
  'logout_reset': '登出/重置',
  
  'power_smoothing': '功率平滑',
  'vibration': '振动',
  'show_power_zones': '显示功率区间',
  
  'username': '用户名',
  'rider_weight': '骑手体重',
  'bike_weight': '自行车重量',
  
  'connect': '连接',
  'disconnect': '断开',
  
  'dashboard': '仪表板',
  'schedule': '日程',
  'progress': '进度',
  'start_now': '立即开始',
  'interval': '间隔',
  'cadence': '踏频',
  'power': '功率',
  'heart_rate': '心率',
  
  'save': '保存',
  'cancel': '取消',
  'connected': '已连接',
  'not_connected': '未连接',
  'workout_library': '训练库',
  'start': '开始',
  'no_devices_found': '未找到设备',
  'select_device_type': '连接为:',
};

const Map<String, String> _zhTW = {
  'settings': '設定',
  'sport': '運動',
  'cycling': '騎行',
  'add_devices': '添加設備',
  'other_options': '其他選項',
  'language': '語言',
  'account_info': '帳戶資訊',
  'connections': '連接',
  'guide': '指南',
  'subscription_status': '訂閱狀態',
  'active': '活躍',
  'logout_reset': '登出/重置',
  
  'power_smoothing': '功率平滑',
  'vibration': '振動',
  'show_power_zones': '顯示功率區間',
  
  'username': '用戶名',
  'rider_weight': '騎手體重',
  'bike_weight': '自行車重量',
  
  'connect': '連接',
  'disconnect': '斷開',
  
  'dashboard': '儀表板',
  'schedule': '日程',
  'progress': '進度',
  'start_now': '立即開始',
  'interval': '間隔',
  'cadence': '踏頻',
  'power': '功率',
  'heart_rate': '心率',
  
  'save': '保存',
  'cancel': '取消',
  'connected': '已連接',
  'not_connected': '未連接',
  'workout_library': '訓練庫',
  'start': '開始',
  'no_devices_found': '未找到設備',
  'select_device_type': '連接為:',
};
