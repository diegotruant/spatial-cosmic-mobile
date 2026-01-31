import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14), 
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informativa sulla Privacy',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            
            _SectionTitle(title: '1. Introduzione'),
            _SectionText(text: 'La presente Informativa sulla Privacy descrive come Sporting Performance raccoglie, utilizza e protegge i tuoi dati personali quando utilizzi la nostra piattaforma (app mobile e web).'),

            _SectionTitle(title: '2. Dati Raccolti e Memoria Locale'),
            _SectionText(text: 'L\'app utilizza la memoria del tuo dispositivo per salvare:\n• Preferenze (es. FC Max, FTP).\n• Token di accesso.\n• File degli allenamenti svolti.\n\nQuesti dati vengono inviati ai nostri server o servizi terzi (Strava, Intervals.icu) solo se autorizzati.'),

            _SectionTitle(title: '3. Dati Fisiologici'),
            _SectionText(text: 'Trattiamo dati sensibili come Frequenza Cardiaca, HRV e Potenza esclusivamente per finalità di analisi sportiva e calcolo della readiness. Questi dati non vengono condivisi con terze parti per scopi pubblicitari.'),

            _SectionTitle(title: '4. Diritti dell\'Utente'),
            _SectionText(text: 'Puoi richiedere la cancellazione dei tuoi dati o l\'esportazione contattando il supporto. Puoi revocare le connessioni esterne in qualsiasi momento dalle impostazioni.'),

            _SectionTitle(title: '5. Contatti'),
            _SectionText(text: 'Truant Diego Dino\nFontanafredda (PN), Italia\nEmail: support@sportingperformance.com'),

            SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
      ),
    );
  }
}
