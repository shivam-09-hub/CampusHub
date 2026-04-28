import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Current mode: 'login' or 'signup'
  String _authMode = 'login';

  // Current role: 'admin' or 'student'
  String _selectedRole = 'admin';

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auth Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signIn(email, password);
      if (user == null) {
        _showSnack('Account not found. Please contact your admin.',
            isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Verify role matches selection
      if (_selectedRole == 'student' && user.isAdmin) {
        _showSnack('This is an admin account. Please use Admin login.',
            isError: true);
        await _authService.signOut();
        setState(() => _isLoading = false);
        return;
      }
      if (_selectedRole == 'admin' && user.isStudent) {
        _showSnack('This is a student account. Please use Student login.',
            isError: true);
        await _authService.signOut();
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      if (user.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => StudentDashboard(user: user)),
        );
      }
    } on AuthException catch (e) {
      String msg = 'Login failed. Please try again.';
      final detail = e.message.toLowerCase();
      if (detail.contains('invalid login credentials')) {
        msg = 'Invalid email or password.';
      }
      if (detail.contains('email')) msg = 'Invalid email address.';
      _showSnack(msg, isError: true);
    } catch (e) {
      print('Login error: $e');
      _showSnack('Something went wrong. $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAdminSignUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showSnack('Please fill in all fields', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.createAdminAccount(
        email: email,
        password: password,
        name: name,
      );

      if (!mounted) return;

      _showSnack('Admin account created successfully!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
      );
    } on AuthException catch (e) {
      String msg = 'Account creation failed.';
      final detail = e.message.toLowerCase();
      if (detail.contains('already')) msg = 'This email is already registered.';
      if (detail.contains('password')) msg = 'Password is too weak.';
      if (detail.contains('email')) msg = 'Invalid email address.';
      _showSnack(msg, isError: true);
    } catch (e) {
      print('Signup error: $e');
      _showSnack('Something went wrong: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email address first to reset password',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(email);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_read,
                    color: AppTheme.success, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Email Sent'),
            ],
          ),
          content: const Text(
              'Password reset email sent. Please check Inbox, Spam, or Promotions folder.\n\n'
              'Important: If the email is in spam, please mark it as "Not Spam" to ensure future delivery.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      String msg = 'Failed to send reset email.';
      if (e.message.toLowerCase().contains('email')) {
        msg = 'Invalid email address.';
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _switchAuthMode(String mode) {
    setState(() {
      _authMode = mode;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nameCtrl.clear();
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    showAppSnackBar(context, msg, isError: isError);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _authMode == 'signup'
            ? 'Creating admin account...'
            : 'Signing in...',
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildRoleSelector(),
                  const SizedBox(height: 28),
                  if (_authMode == 'signup')
                    _buildSignUpForm()
                  else
                    _buildLoginForm(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    final bool isSignUp = _authMode == 'signup';

    final String title;
    final String subtitle;
    final IconData icon;

    if (isSignUp) {
      title = 'Create\nAccount';
      subtitle = 'Register a new admin account';
      icon = Icons.person_add_rounded;
    } else {
      title = 'Welcome\nBack';
      subtitle = _selectedRole == 'admin'
          ? 'Sign in as Admin / Faculty'
          : 'Sign in as Student';
      icon = Icons.school_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Role Selector (Admin / Student)
  // ---------------------------------------------------------------------------

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _roleCard(
                  'admin', 'Admin / Faculty', Icons.admin_panel_settings_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _roleCard('student', 'Student', Icons.school_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleCard(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          // Students can only login, not sign up
          if (role == 'student') _authMode = 'login';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(isDark ? 0.15 : 0.08)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withOpacity(isDark ? 0.25 : 0.15)
                    : isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppTheme.primary
                      : isDark
                          ? Colors.white54
                          : Colors.grey.shade500,
                  size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Login Form (for both Admin and Student)
  // ---------------------------------------------------------------------------

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedRole == 'admin' ? 'Admin Sign In' : 'Student Sign In',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 20),

        // Email field
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.subtitleColor(context),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),

        // Forgot Password button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isLoading ? null : _handleForgotPassword,
            icon: const Icon(Icons.lock_reset, size: 18),
            label: const Text(
              'Forgot Password?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        // Admin: "Don't have an account? Sign Up"
        if (_selectedRole == 'admin') ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                    color: AppTheme.subtitleColor(context), fontSize: 14),
              ),
              GestureDetector(
                onTap: () => _switchAuthMode('signup'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Student info notice
        if (_selectedRole == 'student') ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.isDark(context)
                  ? Colors.amber.shade900.withOpacity(0.2)
                  : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.isDark(context)
                    ? Colors.amber.shade700.withOpacity(0.3)
                    : Colors.amber.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Students cannot create accounts.\nPlease contact your admin for login credentials.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.isDark(context)
                          ? Colors.amber.shade200
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Admin Sign-Up Form
  // ---------------------------------------------------------------------------

  Widget _buildSignUpForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.adaptiveShadow(context),
        border: AppTheme.isDark(context)
            ? Border.all(color: AppTheme.borderColor(context))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(
                  AppTheme.isDark(context) ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🔐 Admin Registration',
              style: TextStyle(
                  color: AppTheme.isDark(context)
                      ? const Color(0xFFA5B4FC)
                      : AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create Admin Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Register as a new admin / faculty member.',
            style: TextStyle(
                color: AppTheme.subtitleColor(context), fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Full Name
          TextField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Dr. Sharma',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          // Email
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'admin@college.edu',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),

          // Password
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleAdminSignUp(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Minimum 6 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.subtitleColor(context),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleAdminSignUp,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Create Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // "Already have an account? Sign In"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                    color: AppTheme.subtitleColor(context), fontSize: 14),
              ),
              GestureDetector(
                onTap: () => _switchAuthMode('login'),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
