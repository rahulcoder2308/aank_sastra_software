import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _localError;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _localError = null);

      try {
        await context.read<AuthProvider>().login(
          _usernameController.text,
          _passwordController.text,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _localError = e.toString().replaceAll('Exception: ', '');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          if (isNarrow) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildLoginForm(),
              ),
            );
          }

          return Row(
            children: [
              // Left Section - Branding
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        Color(0xFF1B5E20), // Darker green
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Opacity(
                          opacity: 0.15,
                          child: Image.asset(
                            'assets/images/login_bg.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(60.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/logo_symbol.jpg',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'AANK SASTRA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Numerology & Business Management System',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 48),
                            _buildFeatureItem(
                              Icons.security,
                              'Secure Data Management',
                            ),
                            _buildFeatureItem(
                              Icons.analytics_outlined,
                              'Advanced Numerology Analysis',
                            ),
                            _buildFeatureItem(
                              Icons.business_center_outlined,
                              'Business Planning & Tracking',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Section - Login Form
              Expanded(
                flex: 1,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40.0),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginForm() {
    final auth = context.watch<AuthProvider>();
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back 👋',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to continue your strategic destiny',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'Enter Email',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Enter password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _localError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child:
                        auth.isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
                : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
