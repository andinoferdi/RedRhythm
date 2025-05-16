import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routes.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  // Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Handle registration
  Future<void> _handleRegister() async {
    // Always validate the form
    final isValid = _formKey.currentState!.validate();
    
    // Check terms agreement
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Only proceed if form is valid
    if (isValid) {
      final controller = ref.read(authControllerProvider.notifier);
      await controller.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    } else {
      // Show a general error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors in the form before proceeding'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle field submission for the confirm password field
  void _handleConfirmPasswordSubmit(String _) async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    // Process registration
    await _handleRegister();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    // Handle authentication state changes
    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.registrationSuccess) {
        // Navigate to login screen after successful registration
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage ?? 'Registration successful! You can now log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to auth options screen
            Navigator.of(context).pushReplacementNamed(AppRoutes.authOptions);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            // Only validate when submitting or after first submit
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: () {
              // Only validate when form has been submitted once
              if (_formKey.currentState?.validate() ?? false) {
                // Form is valid, no need to do anything
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/wave_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Create your account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: _handleConfirmPasswordSubmit,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreeTerms = !_agreeTerms;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _agreeTerms ? const Color(0xFFE71E27) : Colors.white,
                            width: 2,
                          ),
                          color: _agreeTerms ? const Color(0xFFE71E27) : Colors.transparent,
                        ),
                        child: _agreeTerms
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.status == AuthStatus.loading
                        ? null
                        : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71E27),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: authState.status == AuthStatus.loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE71E27),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        obscureText: isPassword && obscureText,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        enableInteractiveSelection: true,
        enableSuggestions: !isPassword,
        autocorrect: !isPassword,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        cursorColor: const Color(0xFFE71E27),
        showCursor: true,
        readOnly: false,
        enableIMEPersonalizedLearning: true,
        toolbarOptions: const ToolbarOptions(
          copy: true,
          cut: true,
          paste: true,
          selectAll: true,
        ),
        onChanged: (value) {
          controller.value = TextEditingValue(
            text: value,
            selection: controller.selection,
          );
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE71E27), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 