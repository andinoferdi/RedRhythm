import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import '../routes/app_router.dart';

@RoutePage()
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
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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
      await ref.read(authControllerProvider.notifier).register(
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
    ref.listen<AuthState>(authControllerProvider, (previous, state) {
      if (state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        context.router.replace(const LoginRoute());
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
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
          onPressed: () => context.router.pop(),
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
                    Expanded(
                      child: Text(
                        'I agree to the Terms and Conditions',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE71E27),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: authState.isLoading
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
                      onTap: () => context.router.replace(const LoginRoute()),
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
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.editableText(
            editableTextState: editableTextState,
          );
        },
        onChanged: (value) {
          controller.value = TextEditingValue(
            text: value,
            selection: controller.selection,
          );
        },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.6),
            fontFamily: 'Poppins',
          ),
          prefixIcon: Icon(
            icon,
            color: const Color.fromRGBO(255, 255, 255, 0.6),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color.fromRGBO(255, 255, 255, 0.6),
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