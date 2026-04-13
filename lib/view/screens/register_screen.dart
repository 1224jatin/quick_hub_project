import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../view_models/auth_view_model.dart';
import 'login_screen.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  UserRole _selectedRole = UserRole.consumer;
  String _selectedGender = 'Male';

  void _handleRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authVM = context.read<AuthViewModel>();

      if (_selectedRole == UserRole.provider) {
        _sendEmailToAdmin();
      } else {
        final success = await authVM.registerUser(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authVM.errorMessage ?? "Registration Failed"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _sendEmailToAdmin() async {
    final String adminEmail = "admin@quickhub.com";
    final String subject = "New Service Provider Application: ${_nameController.text}";
    final String body = "Hello Admin,\n\nA new user wants to register as a Service Provider on Quick Hub.\n\nDetails:\n- Name: ${_nameController.text}\n- Email: ${_emailController.text}\n- City: ${_cityController.text}\n- Age: ${_ageController.text}\n- Gender: $_selectedGender\n- Skills/Services: ${_skillsController.text}\n\nPlease review this application.";

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: adminEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application email drafted! Please send it to proceed.")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app. Please email admin@quickhub.com manually.")),
        );
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: MyCustomClipper(),
              child: Container(
                height: 220,
                width: double.infinity,
                color: theme.primaryColor,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedRole == UserRole.consumer ? "Create Account" : "Partner with Us",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRole == UserRole.consumer 
                            ? "Join the Quick Hub Community" 
                            : "Submit your details to start earning",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildRoleToggle(isDark, theme),
                    const SizedBox(height: 25),

                    _buildTextField(_nameController, "Full Name", Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildTextField(_emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    
                    if (_selectedRole == UserRole.consumer) ...[
                      const SizedBox(height: 15),
                      _buildTextField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                    ],

                    if (_selectedRole == UserRole.provider) ...[
                      const SizedBox(height: 15),
                      _buildTextField(_cityController, "City", Icons.location_city),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_ageController, "Age", Icons.calendar_today, keyboardType: TextInputType.number)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: const InputDecoration(labelText: "Gender"),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => _selectedGender = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_skillsController, "Skills (e.g. Plumbing, Cleaning)", Icons.build_outlined),
                      const SizedBox(height: 10),
                      const Text(
                        "Your application will be reviewed by our team.",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 30),
                    Consumer<AuthViewModel>(
                      builder: (context, authVM, child) {
                        if (authVM.isLoading) return const CircularProgressIndicator();
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          onPressed: () => _handleRegister(context),
                          child: Text(_selectedRole == UserRole.consumer ? "Sign up" : "Submit Application"),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLoginLink(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildRoleToggle(bool isDark, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.primaryLightBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildRoleButton(UserRole.consumer, "Need Services", theme),
          _buildRoleButton(UserRole.provider, "Provide Services", theme),
        ],
      ),
    );
  }

  Widget _buildRoleButton(UserRole role, String label, ThemeData theme) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account? ", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          child: const Text("Log In", style: TextStyle(color: AppTheme.primaryDarkBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
