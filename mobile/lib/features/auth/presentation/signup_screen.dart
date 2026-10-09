import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_shop_app/core/theme/app_theme.dart';
import 'package:repair_shop_app/features/auth/presentation/auth_notifier.dart';
import 'package:repair_shop_app/features/dashboard/presentation/dashboard_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers
  final _shopNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown States
  String _selectedShopType = 'Mobile Repair';
  String _selectedCountryCode = '+91';
  String _selectedCurrency = '₹';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _shopTypes = [
    'Mobile Repair',
    'Laptop Repair',
    'Computer Repair',
    'Electronics Repair'
  ];

  final List<String> _countryCodes = ['+91', '+1', '+44', '+971', '+61', '+86'];
  final List<String> _currencies = ['₹', r'$', '€', '£', '¥', 'AED'];

  @override
  void dispose() {
    _shopNameController.dispose();
    _gstController.dispose();
    _ownerNameController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).signup(
            shopType: _selectedShopType,
            shopName: _shopNameController.text.trim(),
            gstNumber: _gstController.text.trim(),
            ownerName: _ownerNameController.text.trim(),
            username: _usernameController.text.trim(),
            mobileNumber: _mobileController.text.trim(),
            countryCode: _selectedCountryCode,
            shopAddress: _addressController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            currencySymbol: _selectedCurrency,
          );

      if (mounted) {
        if (success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: AppTheme.premiumGradient(context),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get started with your repair shop management',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Registration Form Box
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassmorphicBox(context),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Register Shop Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),

                          // Shop Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedShopType,
                            decoration: const InputDecoration(
                              labelText: 'Shop Type',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            items: _shopTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedShopType = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Shop Name
                          TextFormField(
                            controller: _shopNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Shop Name',
                              prefixIcon: Icon(Icons.edit_note_outlined),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Shop name is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // GST Number (Optional)
                          TextFormField(
                            controller: _gstController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'GST Number (Optional)',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Owner Name
                          TextFormField(
                            controller: _ownerNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Owner Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) =>
                                (val == null || val.trim().isEmpty) ? 'Owner name is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Community Username (Unique, no spaces)
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Community Username',
                              prefixIcon: Icon(Icons.alternate_email_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Username is required';
                              }
                              if (val.contains(' ')) {
                                return 'Username must not contain spaces';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mobile Number with Country Code Dropdown
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 95,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCountryCode,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                                  ),
                                  items: _countryCodes.map((code) {
                                    return DropdownMenuItem(value: code, child: Text(code));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCountryCode = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Mobile Number',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(val) == null) {
                                      return 'Must be numeric';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Currency Selector
                          DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Business Currency',
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                            items: _currencies.map((symbol) {
                              return DropdownMenuItem(value: symbol, child: Text('$symbol ($symbol)'));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCurrency = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Shop Address (Optional)
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Shop Address (Optional)',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!regex.hasMatch(value.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password is required';
                              if (val.length < 8) return 'Minimum 8 characters required';
                              if (!val.contains(RegExp(r'[A-Z]'))) return 'Must contain 1 uppercase letter';
                              if (!val.contains(RegExp(r'[a-z]'))) return 'Must contain 1 lowercase letter';
                              if (!val.contains(RegExp(r'[0-9]'))) return 'Must contain 1 digit number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Please confirm your password';
                              if (val != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Action Register Button
                          ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleSignup,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Register Shop & Owner'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Return to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
