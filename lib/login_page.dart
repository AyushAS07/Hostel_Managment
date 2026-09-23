import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'link_utils.dart';
import 'registration_page.dart';
import 'services/api_service.dart';
import 'admin/admin_shell.dart';
import 'student/student_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Login', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 22)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/sliderjj.jpg', fit: BoxFit.cover),
                  Container(color: Colors.black45),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'RIT Hostel',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                                child: const Text('Home', style: TextStyle(color: Colors.white70)),
                              ),
                              const Text('•', style: TextStyle(color: Colors.white54)),
                              const Text('Login', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign in',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Same fields as the website login page (email & password).',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Enter your email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your password';
                                  if (v.length < 4) return 'At least 4 characters (demo)';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _showForgotPassword,
                                  child: const Text('Forgot password'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _isSubmitting ? null : _onSignIn,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.blue[800],
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Sign in'),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 12),
                              Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(builder: (_) => const RegistrationPage()),
                                  );
                                },
                                child: const Text('Sign up'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 600) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: _QuotePanel(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (MediaQuery.sizeOf(context).width < 600)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: _QuotePanel(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome ${result['user']?['name'] ?? 'back'}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final role = result['user'] is Map<String, dynamic>
          ? (result['user'] as Map<String, dynamic>)['role']?.toString() ?? 'student'
          : 'student';
      await _navigateToRoleShell(role);
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _navigateToRoleShell(String role) async {
    if (!mounted) return;
    Widget page;
    if (role == 'admin') {
      page = const AdminShell();
    } else {
      page = const StudentShell();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final message = await ApiService.forgotPassword(
                  _emailController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
                );
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Request reset'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchPhone(context, '+919937159477');
            },
            child: const Text('Call office'),
          ),
        ],
      ),
    );
  }
}

class _QuotePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '"Best thing that\'s happened this year? Maybe Hostel.\n'
          'It was a great experience.\nI loved it."',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            height: 1.5,
            color: Colors.blueGrey[800],
          ),
        ),
      ),
    );
  }
}
