import 'package:flutter/material.dart';
import 'app_urls.dart';
import 'link_utils.dart';
import 'services/api_service.dart';

class AdmissionPage extends StatefulWidget {
  const AdmissionPage({super.key});

  @override
  State<AdmissionPage> createState() => _AdmissionPageState();
}

class _AdmissionPageState extends State<AdmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _collegeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _course;
  String? _yearOfStudy;
  String? _department;
  String? _hostelType;
  String? _roomType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _collegeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Admission Form'),
        backgroundColor: Colors.blue[800],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTextField('Full Name*', 'Enter your name', controller: _fullNameController),
              _buildTextField('College ID*', 'Enter your ID', controller: _collegeIdController),
              _buildTextField(
                'Email Address*',
                'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                'Phone Number*',
                'Enter your phone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 25),
              const Text('Academic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildDropdownField(
                'Course*',
                ['B.Tech', 'M.Tech', 'BCA', 'MCA', 'Other'],
                onChanged: (value) => _course = value,
              ),
              _buildDropdownField(
                'Year of Study*',
                ['First Year', 'Second Year', 'Third Year', 'Fourth Year'],
                onChanged: (value) => _yearOfStudy = value,
              ),
              _buildDropdownField(
                'Department*',
                ['Computer Science', 'Information Technology', 'Mechanical', 'Civil', 'Other'],
                onChanged: (value) => _department = value,
              ),

              const SizedBox(height: 25),
              const Text('Hostel Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildDropdownField(
                'Hostel Type*',
                ['Boys Hostel', 'Girls Hostel'],
                onChanged: (value) => _hostelType = value,
              ),
              _buildDropdownField(
                'Room Type*',
                ['Single Occupancy', 'Double Occupancy', 'Triple Occupancy'],
                onChanged: (value) => _roomType = value,
              ),

              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAdmission,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Application', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => launchExternalUrl(context, AppUrls.ritCollegeHome),
                icon: const Icon(Icons.open_in_new),
                label: const Text('RIT college website (more information)'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAdmission() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    try {
      final message = await ApiService.submitAdmission(
        fullName: _fullNameController.text.trim(),
        collegeId: _collegeIdController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        course: _course ?? '',
        yearOfStudy: _yearOfStudy ?? '',
        department: _department ?? '',
        hostelType: _hostelType ?? '',
        roomType: _roomType ?? '',
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTextField(
    String label,
    String hint, {
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items, {
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please select $label';
          return null;
        },
      ),
    );
  }
}
