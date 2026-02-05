import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  final _resetEmailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await authService.signIn(email, password);
      } else {
        await authService.signUp(email, password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login if not auto-logged in.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("AuthException(message: ", "").replaceAll(")", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendResetEmail() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _resetEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una email valida.')),
      );
      return;
    }

    try {
      await authService.sendPasswordReset(
        email,
        redirectTo: 'spatialcosmic://spatialcosmic.app/reset',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email di reset inviata. Controlla la posta.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  void _showResetPasswordDialog() {
    _resetEmailController.text = _emailController.text.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Password dimenticata', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _resetEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => _sendResetEmail(),
            child: const Text('Invia'),
          ),
        ],
      ),
    );
  }

  void _showAppInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Come usare l'app", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Guida rapida per l'atleta:\n"
          "1) Login: usa email e password ricevute dal coach.\n"
          "2) Profilo: vai in Settings > Informazioni account > Modifica profilo completo e inserisci peso, altezza, massa magra, somatotipo, data di nascita, tempo disponibile e disciplina.\n"
          "3) Connessioni: collega Oura (se hai l'anello) per HRV. Collega Strava solo se il coach ti ha chiesto di sincronizzare attività.\n"
          "4) Home: controlla lo stato del giorno, HRV e prossimi eventi.\n"
          "5) Lab: consulta il profilo metabolico e le curve (dati dal server).\n"
          "6) Schedule: qui trovi i workout assegnati dal coach.\n"
          "7) Test: esegui solo se richiesto dal coach.\n"
          "8) Workout: apri un workout e premi Start. Se HRV è rosso, recupero consigliato.\n"
          "9) Fine workout: salva e analizza. Se vuoi caricarlo sul tuo device, usa Esporta .fit.\n"
          "10) Export .fit: scarica il file e importalo sul dispositivo:\n"
          "   • Garmin: collega via USB → GARMIN/Workouts.\n"
          "   • Wahoo: app ELEMNT → aggiungi allenamento da file.\n"
          "   • Karoo: Hammerhead Dashboard → Upload workout (.fit).\n"
          "   • Bryton: app Bryton Active → Importa allenamento (.fit).\n"
          "11) Problemi: verifica connessioni e dati profilo, poi avvisa il coach.",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.black, // Explicitly black as per app theme
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or Title
                  Icon(
                    Icons.bolt, // Cycling related icon placeholder
                    size: 64,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CyclingCoach',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _showAppInstructions,
                        icon: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
                        tooltip: 'Guida',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Welcome back, Athlete' : 'Join the Ecosystem',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!value.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showResetPasswordDialog,
                        child: const Text('Password dimenticata?', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authService.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? 'Login' : 'Create Account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Mode
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(color: Colors.grey),
                        children: [
                          TextSpan(text: _isLogin ? "Don't have an account? " : "Already have an account? "),
                          TextSpan(
                            text: _isLogin ? "Sign Up" : "Login",
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
