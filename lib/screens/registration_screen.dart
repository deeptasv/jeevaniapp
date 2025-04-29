import 'package:flutter/material.dart';
import 'package:jeevaniapp/screens/farmer_dashboard.dart';
import 'package:location/location.dart';
import 'package:jeevaniapp/services/auth_services.dart';
import 'package:jeevaniapp/screens/buyer_dashboard.dart';
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  String _name = '';
  String _phone = '';
  String _location = '';
  String _password = '';
  String _userType = 'Buyer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _useCurrentLocation = true;
  final Location _locationService = Location();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Moved _getCurrentLocation inside the class
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    locationData = await _locationService.getLocation();
    setState(() {
      _location = '${locationData.latitude}, ${locationData.longitude}';
    });
  }

  void _submitForm() async {
    debugPrint('Submitting form...');
    if (_formKey.currentState!.validate()) {
      debugPrint('Form validated successfully.');
      _formKey.currentState!.save();
      debugPrint('Form saved: name=$_name, phone=$_phone, location=$_location, userType=$_userType');
      setState(() => _isLoading = true);
      try {
        debugPrint('Calling registerUser...');
        final regResult = await _authService.registerUser(
          role: _userType.toLowerCase(),
          name: _name,
          phone: _phone,
          location: _location,
          password: _password,
        );
        debugPrint('Registration result: $regResult');

        // Auto-login after registration
        debugPrint('Attempting auto-login...');
        final loginResult = await _authService.login(
          role: _userType.toLowerCase(),
          phone: _phone,
          password: _password,
        );
        debugPrint('Login result: $loginResult');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loginResult['message'])),
          );
 final userId = loginResult['userId']?.toString() ?? 'defaultUserId';
          debugPrint('Navigating to ${_userType == 'Buyer' ? 'buyer_dashboard' : 'farmer_dashboard'}...');
          if (_userType == 'Buyer') {
            print('LoginScreen: Navigating to BuyerDashboard with buyerId: $userId');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BuyerDashboard(buyerId: userId),
              ),
            );
          }  else {
            print('LoginScreen: Navigating to FarmerDashboard with farmerId: $userId');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FarmerDashboard(farmerId: userId),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Operation failed: $e')),
          );
        }
      } finally {
        if (mounted) {
          debugPrint('Setting isLoading to false.');
          setState(() => _isLoading = false);
        }
      }
    } else {
      debugPrint('Form validation failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: CustomPaint(
              painter: WavePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnimatedLogo(),
                      const SizedBox(height: 24),
                    
                      const SizedBox(height: 32),
                      _buildFormCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/logo.png.jpeg',
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(
                label: 'Name',
                icon: Icons.person,
                onSaved: (value) => _name = value!,
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              _buildInput(
                label: 'Phone Number',
                icon: Icons.phone,
                onSaved: (value) => _phone = value!,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter phone number';
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Enter a valid 10-digit number';
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildLocationInput(),
              const SizedBox(height: 16),
              _buildInput(
                label: 'Password',
                icon: Icons.lock,
                onSaved: (value) => _password = value!,
                validator: (value) => value!.isEmpty ? 'Please enter password' : null,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF56ab2f),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              _buildUserTypeDropdown(),
              const SizedBox(height: 24),
              _buildSignUpButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Location',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _useCurrentLocation = !_useCurrentLocation;
                  _location = '';
                });
              },
              child: Text(
                _useCurrentLocation ? 'Enter Manually' : 'Use Current Location',
                style: const TextStyle(color: Color(0xFF56ab2f)),
              ),
            ),
          ],
        ),
        _useCurrentLocation
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      _location.isEmpty ? 'Fetch your current location' : _location,
                      style: TextStyle(
                        color: _location.isEmpty ? Colors.grey : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFF56ab2f)),
                    onPressed: _getCurrentLocation,
                  ),
                ],
              )
            : TextFormField(
                decoration: InputDecoration(
                  labelText: 'Enter Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF56ab2f)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF56ab2f), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                style: const TextStyle(color: Colors.black87),
                onSaved: (value) => _location = value!,
                validator: (value) => value!.isEmpty ? 'Please enter your location' : null,
              ),
      ],
    );
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF56ab2f)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF56ab2f), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: const TextStyle(color: Colors.black87),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildUserTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<String>(
        value: _userType,
        items: ['Buyer', 'Farmer'].map((type) {
          return DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Icon(
                  type == 'Buyer' ? Icons.shopping_cart : Icons.agriculture,
                  color: const Color(0xFF56ab2f),
                ),
                const SizedBox(width: 8),
                Text(type, style: const TextStyle(color: Colors.black87)),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _userType = value!);
        },
        decoration: const InputDecoration(
          labelText: 'User Type',
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF56ab2f)),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Custom Painter for Wave Background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFa8e063).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.2,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}