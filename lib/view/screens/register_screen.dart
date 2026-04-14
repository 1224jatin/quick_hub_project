import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  UserRole _selectedRole = UserRole.consumer;
  String _selectedGender = 'Male';
  
  String? _selectedState;
  String? _selectedCity;
  bool isSending = false;
  String? _generatedOtp;

  final Map<String, List<String>> _statesAndCities = {
    'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala', 'Mohali', 'Bathinda'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'West Delhi', 'East Delhi'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad'],
    'Karnataka': ['Bengaluru', 'Mysore', 'Hubballi', 'Belagavi', 'Mangaluru'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Meerut', 'Varanasi'],
    'Haryana': ['Gurugram', 'Faridabad', 'Panipat', 'Ambala', 'Karnal'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
  };

  void _handleRegister(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == UserRole.provider) {
        if (_selectedState == null || _selectedCity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select State and City")),
          );
          return;
        }
        _sendEmailToAdmin();
      } else {
        _startOtpVerification();
      }
    }
  }

  void _startOtpVerification() async {
    setState(() => isSending = true);
    _generatedOtp = (Random().nextInt(900000) + 100000).toString();
    
    final success = await _sendEmailViaEmailJS(
      templateParams: {
        'name': _nameController.text,
        'email': _emailController.text,
        'otp': _generatedOtp,
        'type': 'OTP Verification'
      }
    );

    setState(() => isSending = false);

    if (success && mounted) {
      _showOtpDialog();
    }
  }

  Future<bool> _sendEmailViaEmailJS({required Map<String, dynamic> templateParams}) async {
    const serviceId = 'service_gcr01ra';
    const tempId = 'template_e82ltum';
    const publicKey = 'ON_pVSKX8vhc3XEhM';
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': tempId,
          'user_id': publicKey,
          'template_params': templateParams
        })
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _showOtpDialog() {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Email"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("An OTP has been sent to your email. Please enter it below."),
            const SizedBox(height: 15),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter 6-digit OTP"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text == _generatedOtp) {
                Navigator.pop(context);
                _completeRegistration();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid OTP. Please try again.")),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void _completeRegistration() async {
    final authVM = context.read<AuthViewModel>();
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

  Future<void> _sendEmailToAdmin() async {
    setState(() => isSending = true);
    final success = await _sendEmailViaEmailJS(
      templateParams: {
        'name': _nameController.text,
        'email': _emailController.text,
        'role': 'Provider',
        'age': _ageController.text,
        'gender': _selectedGender,
        'skills': _skillsController.text,
        'city': _selectedCity ?? '',
        'state': _selectedState ?? '',
        'time': DateTime.now().toLocal().toString().split('.')[0]
      }
    );

    setState(() => isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Application Submitted Successfully" : "Submission Failed")),
      );
      if (success) {
        setState(() {
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _ageController.clear();
          _skillsController.clear();
          _selectedState = null;
          _selectedCity = null;
        });
      }
    }
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.primaryDarkBlue : AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRole == UserRole.consumer 
                            ? "Join the Quick Hub Community" 
                            : "Submit your details to start earning",
                        style: TextStyle(
                          color: isDark ? AppTheme.primaryDarkBlue : AppTheme.white,
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
                    const SizedBox(height: 15),
                    _buildTextField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                    
                    if (_selectedRole == UserRole.provider) ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(labelText: "Select State", prefixIcon: Icon(Icons.map_outlined)),
                        items: _statesAndCities.keys.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
                        onChanged: (val) => setState(() { _selectedState = val; _selectedCity = null; }),
                        validator: (val) => val == null ? "Required" : null,
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(labelText: "Select City", prefixIcon: Icon(Icons.location_city)),
                        items: _selectedState == null ? [] : _statesAndCities[_selectedState]!.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                        onChanged: (val) => setState(() => _selectedCity = val),
                        disabledHint: const Text("Select a state first"),
                        validator: (val) => val == null ? "Required" : null,
                      ),
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
                    ],

                    const SizedBox(height: 30),
                    Consumer<AuthViewModel>(
                      builder: (context, authVM, child) {
                        if ((authVM.isLoading == true) || isSending) return const CircularProgressIndicator();
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : AppTheme.primaryLightBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildRoleButton(UserRole.consumer, "Need Services", theme, isDark),
          _buildRoleButton(UserRole.provider, "Provide Services", theme, isDark),
        ],
      ),
    );
  }

  Widget _buildRoleButton(UserRole role, String label, ThemeData theme, bool isDark) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              color: isSelected ? (isDark ? AppTheme.primaryDarkBlue : Colors.white) : (isDark ? Colors.white70 : AppTheme.primaryDarkBlue),
            ),
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
          child: Text("Log In", style: TextStyle(color:isDark ? AppTheme.white : AppTheme.primaryDarkBlue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
