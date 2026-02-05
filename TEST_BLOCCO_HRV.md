# Test Virtuale - Blocco Workout/Test con HRV RED

## Scenario Test

### Setup
1. Utente: `test@example.com`
2. HRV ultima misurazione: 25ms (RED - sotto baseline di -20%)
3. Traffic Light in database: `RED`

### Comportamento Atteso

#### Dashboard - Card Workout del Giorno
- ✅ Pulsante "INIZIA ALLENAMENTO" diventa "RECUPERO RICHIESTO"
- ✅ Pulsante disabilitato (non cliccabile)
- ✅ Colore rosso invece di blu
- ✅ Tooltip mostra che l'atleta deve recuperare

#### Dashboard - Pulsante TEST
- ✅ Pulsante "TEST" diventa "RECUPERO"
- ✅ Pulsante disabilitato
- ✅ Icona cambia da library a ban
- ✅ Colore rosso

### Implementazione

#### PhysiologicalService
```dart
bool get isWorkoutBlocked {
  if (_history.isEmpty) return false;
  final lastHrv = _history.first;
  return lastHrv.trafficLight?.toUpperCase() == 'RED';
}

bool get isTestBlocked {
  if (_history.isEmpty) return false;
  final lastHrv = _history.first;
  final light = lastHrv.trafficLight?.toUpperCase();
  return light == 'RED' || light == 'YELLOW';
}
```

#### Dashboard - Workout Button
```dart
Consumer<PhysiologicalService>(
  builder: (context, physiological, _) {
    final isBlocked = physiological.isWorkoutBlocked;
    return ElevatedButton(
      onPressed: (workout != null && !isBlocked) ? () {...} : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isBlocked ? Colors.red : Colors.blueAccent,
        // ...
      ),
      child: Text(
        isBlocked ? 'RECUPERO RICHIESTO' : 'INIZIA ALLENAMENTO'
      ),
    );
  },
)
```

## Test Manuale

1. Accedi con un utente
2. Vai su HRV Measurement
3. Inserisci HRV molto bassa (es. 15ms se baseline è ~40ms)
4. Torna alla dashboard
5. Verifica che:
   - Gauge mostra RED
   - Pulsante workout è rosso e disabilitato
   - Pulsante TEST è rosso e disabilitato

## Nota

Il blocco funziona SOLO se:
- L'atleta ha almeno una misurazione HRV in `diary_entries`
- Il `traffic_light` è calcolato e salvato correttamente
- Il `PhysiologicalService` ha caricato i dati con `fetchHistory()`


