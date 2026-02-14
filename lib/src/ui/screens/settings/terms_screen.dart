import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14), // Dark background matching app theme
      appBar: AppBar(
        title: const Text('Termini e Condizioni', style: TextStyle(color: Colors.white)),
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
            
            _SectionTitle(title: 'Chi siamo'),
            _SectionText(text: 'Il titolare del trattamento dei dati è Truant Diego. L\'applicazione è sviluppata per il monitoraggio delle prestazioni sportive.'),

            _SectionTitle(title: 'Dati Raccolti e Memoria Locale'),
            _SectionText(text: 'L\'applicazione non utilizza "cookie" nel senso tradizionale dei siti web. Invece, utilizza la memoria sicura del tuo dispositivo per salvare:\n• Le tue preferenze (es. FC Max, FTP).\n• I token di accesso per mantenere la sessione attiva.\n• I file degli allenamenti svolti (.fit).\n\nQuesti dati restano sul tuo dispositivo e vengono inviati ai nostri server (o servizi terzi connessi) solo tramite connessioni sicure.'),

            _SectionTitle(title: 'Servizi di Terze Parti'),
            _SectionText(text: 'L\'app può integrarsi con piattaforme esterne come Intervals.icu, Strava o Dropbox su tua esplicita richiesta. Quando colleghi questi servizi, accetti che i tuoi dati di allenamento vengano trasmessi a loro secondo le loro rispettive normative sulla privacy.'),

            _SectionTitle(title: 'Per quanto tempo conserviamo i tuoi dati'),
            _SectionText(text: 'Conserviamo i dati del tuo profilo e lo storico degli allenamenti per tutto il tempo in cui il tuo account è attivo per permetterti di analizzare i tuoi progressi.'),

            _SectionTitle(title: 'Quali diritti hai sui tuoi dati'),
            _SectionText(text: 'Puoi richiedere in qualsiasi momento l\'esportazione di tutti i tuoi dati o la cancellazione completa del tuo account e dei dati associati contattando il supporto.'),

            _SectionTitle(title: 'Informazioni di contatto'),
            _SectionText(text: 'Per qualsiasi richiesta riguardante la privacy:\n\nTruant Diego Dino\nVia Brugnera 4/C\n33074 Fontanafredda (PN)'),
            
            _SectionTitle(title: 'Sicurezza e Crittografia'),
            _SectionText(text: 'La sicurezza dei tuoi dati è prioritaria:\n\n• Trasmissione: Tutte le comunicazioni tra l\'app e i server avvengono tramite connessioni cifrate (HTTPS/SSL), proteggendo i dati da intercettazioni.\n• Dati Sanitari: I dati biometrici (Battito Cardiaco, Potenza) sono trattati come dati sensibili e utilizzati esclusivamente per le funzionalità di analisi sportiva.\n• Archiviazione: I nostri server adottano misure di sicurezza standard per proteggere i dati da accessi non autorizzati.'),

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
