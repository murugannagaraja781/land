import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/image_picker_service.dart';
import '../../core/utils/land_units.dart';
import '../../core/utils/location_service.dart';
import '../../core/widgets/property_card.dart';
import '../../core/widgets/property_visual.dart';
import '../../models/agent.dart';
import '../../models/notification_item.dart';
import '../../models/property.dart';
import '../../state/app_state_providers.dart';
import 'post_success_screen.dart';

class PostPropertyWizard extends ConsumerStatefulWidget {
  const PostPropertyWizard({super.key});

  @override
  ConsumerState<PostPropertyWizard> createState() => _PostPropertyWizardState();
}

class _PostPropertyWizardState extends ConsumerState<PostPropertyWizard> {
  int _currentStep = 0;
  final int _totalSteps = 8;

  // Form State
  String _selectedPropertyType = 'House';
  final TextEditingController _titleController = TextEditingController();
  int? _selectedBhk = 3;
  int? _selectedBathrooms = 3;
  String _furnishingStatus = 'Semi-Furnished';
  String _facing = 'North';
  final String _floor = 'Ground + 1 Floor';

  // Live Location & GPS
  String _selectedCity = 'Chennai';
  final TextEditingController _areaLocalityController = TextEditingController(text: 'Porur');
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController(text: '600116');
  bool _isDetectingLocation = false;
  double? _latitude = 13.0382;
  double? _longitude = 80.1565;
  String? _gpsStatusText = 'Tap below to capture live GPS coordinates directly from your device.';
  bool _isGpsVerified = false;

  // Pricing
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();

  // Specs & Amenities & Land Units
  final TextEditingController _areaSqFtController = TextEditingController(text: '1800');
  final TextEditingController _carpetSqFtController = TextEditingController();
  String _selectedLandUnit = 'Sq.Ft';
  final TextEditingController _landUnitValueController = TextEditingController();
  final Set<String> _selectedAmenities = {
    '24x7 Security',
    'Covered Car Parking',
    'Power Backup',
    'Rainwater Harvesting',
  };

  // Visuals & Real Device Photos
  int _selectedPhotoSet = 0;
  String? _customImageBase64;
  String? _pickedImageFileName;
  int? _pickedImageSize;
  bool _isPickingImage = false;

  // Description
  final TextEditingController _descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _areaLocalityController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _priceController.dispose();
    _maintenanceController.dispose();
    _areaSqFtController.dispose();
    _carpetSqFtController.dispose();
    _landUnitValueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Post Property (Step ${_currentStep + 1} of $_totalSteps)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Step Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.primaryLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Form(
                key: _formKey,
                child: _buildCurrentStepContent(),
              ),
            ),
          ),

          // Bottom Action Navigation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_currentStep == _totalSteps - 1 ? 'Publish Property' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PropertyType();
      case 1:
        return _buildStep2BasicDetails();
      case 2:
        return _buildStep3Location();
      case 3:
        return _buildStep4Pricing();
      case 4:
        return _buildStep5FeaturesAndAmenities();
      case 5:
        return _buildStep6Images();
      case 6:
        return _buildStep7Description();
      case 7:
        return _buildStep8Preview();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Property Type
  Widget _buildStep1PropertyType() {
    final types = [
      {'name': 'House', 'label': 'Independent House / Villa', 'icon': Icons.home_rounded},
      {'name': 'Apartment', 'label': 'Flat / Apartment', 'icon': Icons.apartment_rounded},
      {'name': 'Plots', 'label': 'Residential Plot', 'icon': Icons.crop_square_rounded},
      {'name': 'Land', 'label': 'Open Land', 'icon': Icons.landscape_rounded},
      {'name': 'Rental', 'label': 'Rental Home', 'icon': Icons.vpn_key_rounded},
      {'name': 'Commercial', 'label': 'Commercial Building', 'icon': Icons.storefront_rounded},
      {'name': 'Shop', 'label': 'Retail Shop / Showroom', 'icon': Icons.shopping_bag_rounded},
      {'name': 'Office', 'label': 'Office Space', 'icon': Icons.business_rounded},
      {'name': 'Farm Land', 'label': 'Farm Land / Grove', 'icon': Icons.nature_people_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('What type of property are you listing?', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Choose the accurate category for maximum buyer visibility', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: types.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final t = types[index];
            final isSelected = t['name'] == _selectedPropertyType;
            return InkWell(
              onTap: () {
                setState(() => _selectedPropertyType = t['name'] as String);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t['label'] as String,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 2: Basic Details
  Widget _buildStep2BasicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Basic Property Details', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Give your property an attractive title and structural details', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),

        // Title
        Text('Property Title *', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'e.g. 3 BHK Luxury Villa in Porur Gardens',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter a property title';
            if (val.trim().length < 8) return 'Title should be at least 8 characters';
            return null;
          },
        ),

        const SizedBox(height: 20),

        // BHK selector (if residential)
        if (!_selectedPropertyType.contains('Land') && !_selectedPropertyType.contains('Plots')) ...[
          Text('Bedrooms (BHK)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 4, 5].map((bhk) {
              final isSelected = _selectedBhk == bhk;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Center(child: Text('$bhk BHK')),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _selectedBhk = bhk),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Bathrooms
          Text('Bathrooms', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3, 4].map((bath) {
              final isSelected = _selectedBathrooms == bath;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Center(child: Text('$bath')),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    onSelected: (_) => setState(() => _selectedBathrooms = bath),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Furnishing status
          Text('Furnishing Status', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppConstants.furnishingOptions.map((f) {
              final isSelected = _furnishingStatus == f;
              return ChoiceChip(
                label: Text(f),
                selected: isSelected,
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                onSelected: (_) => setState(() => _furnishingStatus = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Facing
        Text('Facing Direction', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AppConstants.facingDirections.map((dir) {
            final isSelected = _facing == dir;
            return ChoiceChip(
              label: Text(dir),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              onSelected: (_) => setState(() => _facing = dir),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 3: Location (With Live GPS Detection)
  Widget _buildStep3Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Property Location & GPS', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Capture live GPS coordinates and specify area landmarks', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),

        // Live GPS Action Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isGpsVerified ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isGpsVerified ? AppColors.primary : AppColors.border,
              width: _isGpsVerified ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isGpsVerified ? AppColors.primary : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: _isGpsVerified ? Colors.white : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Live Device GPS',
                              style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            if (_isGpsVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, color: Colors.white, size: 10),
                                    SizedBox(width: 3),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _gpsStatusText ?? 'Tap button below to capture live coordinates.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isGpsVerified ? AppColors.primaryDark : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // GPS Coordinates Display
              if (_latitude != null && _longitude != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${_latitude!.toStringAsFixed(5)}° N, ${_longitude!.toStringAsFixed(5)}° E',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () async {
                          final url = LocationService.getGoogleMapsUrl(_latitude!, _longitude!);
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Test Map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Detect Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDetectingLocation
                      ? null
                      : () async {
                          setState(() {
                            _isDetectingLocation = true;
                            _gpsStatusText = 'Fetching live device location via GPS...';
                          });

                          final result = await LocationService.getCurrentLiveLocation();

                          if (!mounted) return;
                          setState(() {
                            _isDetectingLocation = false;
                            _latitude = result.latitude;
                            _longitude = result.longitude;
                            _isGpsVerified = result.isLiveGps;
                            if (result.isLiveGps) {
                              _gpsStatusText =
                                  'Live GPS Captured! Location: ${result.estimatedArea}, ${result.estimatedCity} (±${result.accuracy.toStringAsFixed(0)}m)';
                              _selectedCity = result.estimatedCity;
                              _areaLocalityController.text = result.estimatedArea;
                              _pincodeController.text = result.postalCode;
                            } else {
                              _gpsStatusText = result.error ?? 'Using calibrated coordinates';
                            }
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.isLiveGps
                                    ? 'Live GPS Location Captured: ${result.estimatedArea}, ${result.estimatedCity}'
                                    : 'Calibrated location set: Porur, Chennai',
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: Text(
                    _isDetectingLocation
                        ? 'Detecting Live Coordinates...'
                        : (_isGpsVerified ? 'Re-Detect GPS Location' : 'Detect Live GPS Location'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // City
        Text('City / District *', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          decoration: const InputDecoration(),
          items: ['Chennai', 'Tenkasi', 'Tirunelveli', 'Coimbatore', 'Madurai', 'Trichy', 'Salem']
              .map((city) {
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCity = val);
          },
        ),

        const SizedBox(height: 20),

        // Locality / Area
        Text('Locality / Area *', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _areaLocalityController,
          decoration: const InputDecoration(
            hintText: 'e.g. Porur, Tambaram, Sholinganallur',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter the area/locality';
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Landmark
        Text('Famous Landmark', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _landmarkController,
          decoration: const InputDecoration(
            hintText: 'e.g. Near Sri Ramachandra Hospital or Metro Station',
          ),
        ),

        const SizedBox(height: 20),

        // Pincode
        Text('Pincode', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 600116'),
        ),
      ],
    );
  }

  // STEP 4: Pricing
  Widget _buildStep4Pricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Pricing & Commercials', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Set your expected price in Indian Rupees', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),

        Text(
          _selectedPropertyType.toLowerCase() == 'rental' ? 'Monthly Rent (₹) *' : 'Expected Price (₹) *',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
            hintText: _selectedPropertyType.toLowerCase() == 'rental' ? 'e.g. 25000' : 'e.g. 8500000 (85 Lakhs)',
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter the price';
            final parsed = double.tryParse(val.replaceAll(',', ''));
            if (parsed == null || parsed <= 0) return 'Please enter a valid price amount';
            return null;
          },
        ),

        const SizedBox(height: 20),

        Text('Monthly Maintenance (₹)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          controller: _maintenanceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
            hintText: 'e.g. 1500 (Optional)',
          ),
        ),

        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pricing will be automatically formatted into Lakhs and Crores for potential buyers.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: Features & Amenities
  Widget _buildStep5FeaturesAndAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Features & Dimensions', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Specify built-up area and key amenities', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),

        // Land Unit Selection Chips
        Text('Area Unit System', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: LandUnitConverter.supportedUnits.map((unit) {
            final isSelected = _selectedLandUnit == unit;
            return ChoiceChip(
              label: Text(unit),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              onSelected: (_) {
                setState(() {
                  _selectedLandUnit = unit;
                  final currentSqFt = int.tryParse(_areaSqFtController.text) ?? 1800;
                  if (unit != 'Sq.Ft') {
                    final converted = LandUnitConverter.fromSqFt(currentSqFt, unit);
                    _landUnitValueController.text = converted.toString();
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // If a Tamil Nadu land unit (Cents, Grounds, Acres, Guntha) is selected:
        if (_selectedLandUnit != 'Sq.Ft') ...[
          Text('$_selectedLandUnit Amount *', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          TextFormField(
            controller: _landUnitValueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'e.g. 4.5',
              suffixText: _selectedLandUnit,
              prefixIcon: const Icon(Icons.crop_landscape_rounded, size: 20),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {
                final sqFt = LandUnitConverter.toSqFt(parsed, _selectedLandUnit);
                setState(() {
                  _areaSqFtController.text = sqFt.toString();
                });
              }
            },
          ),
          const SizedBox(height: 10),
        ],

        // Equivalent / Primary Built-up Area in Sq.Ft
        Text(
          _selectedLandUnit != 'Sq.Ft'
              ? 'Calculated Area in Sq.Ft *'
              : 'Plot / Built-up Area (Sq.Ft) *',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _areaSqFtController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 1850',
            suffixText: 'sq.ft',
            prefixIcon: Icon(Icons.straighten_rounded, size: 20),
          ),
          onChanged: (val) {
            final parsedSqFt = int.tryParse(val);
            if (parsedSqFt != null && _selectedLandUnit != 'Sq.Ft') {
              final converted = LandUnitConverter.fromSqFt(parsedSqFt, _selectedLandUnit);
              setState(() {
                _landUnitValueController.text = converted.toString();
              });
            }
          },
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter the area';
            final parsed = int.tryParse(val);
            if (parsed == null || parsed <= 0) return 'Please enter valid sq.ft';
            return null;
          },
        ),

        // Live Conversion Visual Pill
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tamil Nadu Land Standard: ${LandUnitConverter.formatWithConversion(
                    sqFt: int.tryParse(_areaSqFtController.text) ?? 1800,
                    preferredUnit: _selectedLandUnit,
                    unitValue: double.tryParse(_landUnitValueController.text),
                  )}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text('Select Amenities', style: AppTextStyles.labelLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12.5,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 6: Images / Real Device Photos & Visual Styles
  Widget _buildStep6Images() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 6 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Listing Photos & Visuals', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Take real property photos with your camera or select from gallery', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),

        // Live Upload Section
        if (_customImageBase64 != null) ...[
          // Preview of picked real device photo
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.memory(
                        base64Decode(_customImageBase64!),
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'REAL DEVICE PHOTO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _customImageBase64 = null;
                                _pickedImageFileName = null;
                                _pickedImageSize = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _pickedImageFileName ?? 'Property Photo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                        if (_pickedImageSize != null)
                          Text(
                            '${(_pickedImageSize! / 1024).toStringAsFixed(0)} KB',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          // Photo Pick Action Buttons
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
                const SizedBox(height: 10),
                Text('Upload Real Property Photo', style: AppTextStyles.h3.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'Capture live from camera or select from device gallery',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () async {
                                setState(() => _isPickingImage = true);
                                final picked = await ImagePickerService.pickFromCamera();
                                if (!mounted) return;
                                setState(() {
                                  _isPickingImage = false;
                                  if (picked != null) {
                                    _customImageBase64 = picked.base64Data;
                                    _pickedImageFileName = picked.fileName;
                                    _pickedImageSize = picked.byteSize;
                                  }
                                });
                              },
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () async {
                                setState(() => _isPickingImage = true);
                                final picked = await ImagePickerService.pickFromGallery();
                                if (!mounted) return;
                                setState(() {
                                  _isPickingImage = false;
                                  if (picked != null) {
                                    _customImageBase64 = picked.base64Data;
                                    _pickedImageFileName = picked.fileName;
                                    _pickedImageSize = picked.byteSize;
                                  }
                                });
                              },
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        Text('Or Choose Architectural Visual Preset', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),

        Row(
          children: [0, 1, 2].map((setIndex) {
            final isSelected = _selectedPhotoSet == setIndex && _customImageBase64 == null;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedPhotoSet = setIndex;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      PropertyVisual(
                        propertyType: _selectedPropertyType,
                        visualIndex: setIndex,
                        height: 85,
                        width: double.infinity,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: isSelected ? AppColors.primaryLight : AppColors.surface,
                        child: Center(
                          child: Text(
                            'Style ${setIndex + 1}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 7: Description
  Widget _buildStep7Description() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 7 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Property Overview & Description', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Highlight key selling points, approvals, and neighborhood conveniences', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 24),

        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Describe property features, water availability, road width, nearby schools, hospitals, and connectivity...',
            alignLabelWithHint: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Please enter a description';
            if (val.trim().length < 10) return 'Description should be at least 10 characters';
            return null;
          },
        ),

        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('+ CMDA Approved'),
              onPressed: () {
                _descriptionController.text += ' Fully CMDA & DTCP approved with 100% clear parent documents.';
              },
            ),
            ActionChip(
              label: const Text('+ 24h Water'),
              onPressed: () {
                _descriptionController.text += ' 24 hours Kaveri metro drinking water connection active.';
              },
            ),
            ActionChip(
              label: const Text('+ Close to Metro'),
              onPressed: () {
                _descriptionController.text += ' Just 5 minutes from upcoming metro station and bus terminus.';
              },
            ),
          ],
        ),
      ],
    );
  }

  // STEP 8: Preview
  Widget _buildStep8Preview() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 5000000;
    final area = int.tryParse(_areaSqFtController.text) ?? 1500;
    final title = _titleController.text.isNotEmpty ? _titleController.text : '3 BHK Luxury Villa';
    final location = '${_areaLocalityController.text.trim()}, $_selectedCity';

    final tempProp = Property(
      id: 'preview_id',
      title: title,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Detailed property overview',
      price: price,
      location: location,
      city: _selectedCity,
      propertyType: _selectedPropertyType,
      areaSqFt: area,
      bedrooms: _selectedBhk,
      bathrooms: _selectedBathrooms,
      furnishingStatus: _furnishingStatus,
      facing: _facing,
      floor: _floor,
      amenities: _selectedAmenities.toList(),
      latitude: _latitude,
      longitude: _longitude,
      customImageBase64: _customImageBase64,
      landUnit: _selectedLandUnit,
      landUnitValue: double.tryParse(_landUnitValueController.text),
      agent: const Agent(
        id: 'user_agent',
        name: 'Murugan N (You)',
        agencyName: 'Direct Owner',
        phone: '+91 98401 98765',
        email: 'murugan.properties@gmail.com',
        avatarKey: 'avatar_user',
        rating: 5.0,
        reviewsCount: 12,
        experienceYears: 4,
        totalListings: 3,
        isVerified: true,
        about: 'Verified Direct Owner',
      ),
      postedDate: DateTime.now(),
      status: 'active',
      isVerified: true,
      isFeatured: true,
      isUserPosted: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 8 of 8', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Preview Your Listing', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text('Review how buyers will see your property ad before publishing', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 20),

        // Live preview of the card
        PropertyCard(
          property: tempProp,
          onTap: () {},
          onFavoriteToggle: () {},
        ),

        const SizedBox(height: 16),

        // Live Metadata Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'GPS: ${_latitude?.toStringAsFixed(4)}° N, ${_longitude?.toStringAsFixed(4)}° E',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _isGpsVerified ? 'DEVICE GPS' : 'CALIBRATED',
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: AppColors.borderLight),
              Row(
                children: [
                  const Icon(Icons.photo_camera_back_outlined, size: 16, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    _customImageBase64 != null ? 'Real Device Photo Attached' : 'Architectural Preset Active',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    _selectedLandUnit != 'Sq.Ft'
                        ? '${_landUnitValueController.text} $_selectedLandUnit'
                        : '$area sq.ft',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_done_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Listing is stored locally in offline database and automatically synchronizes with server when online.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleNextStep() async {
    // Validate current step
    if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        _showValidationToast('Please enter a property title');
        return;
      }
    } else if (_currentStep == 2) {
      if (_areaLocalityController.text.trim().isEmpty) {
        _showValidationToast('Please enter the area/locality');
        return;
      }
    } else if (_currentStep == 3) {
      final price = double.tryParse(_priceController.text.replaceAll(',', ''));
      if (price == null || price <= 0) {
        _showValidationToast('Please enter a valid price');
        return;
      }
    } else if (_currentStep == 4) {
      final area = int.tryParse(_areaSqFtController.text);
      if (area == null || area <= 0) {
        _showValidationToast('Please enter a valid sq.ft area');
        return;
      }
    } else if (_currentStep == 6) {
      if (_descriptionController.text.trim().length < 10) {
        _showValidationToast('Please enter a description (at least 10 characters)');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Step 8: Publish
      await _publishProperty();
    }
  }

  Future<void> _publishProperty() async {
    final price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 5000000;
    final area = int.tryParse(_areaSqFtController.text) ?? 1500;
    final maintenance = double.tryParse(_maintenanceController.text.replaceAll(',', ''));
    final location = '${_areaLocalityController.text.trim()}, $_selectedCity';

    final newProp = Property(
      id: 'my_prop_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      location: location,
      city: _selectedCity,
      propertyType: _selectedPropertyType,
      areaSqFt: area,
      superBuiltUpSqFt: (area * 1.15).round(),
      carpetAreaSqFt: (area * 0.85).round(),
      bedrooms: _selectedBhk,
      bathrooms: _selectedBathrooms,
      furnishingStatus: _furnishingStatus,
      facing: _facing,
      floor: _floor,
      maintenanceMonthly: maintenance,
      landmark: _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : null,
      amenities: _selectedAmenities.toList(),
      imageKeys: ['house_1', 'house_2'],
      latitude: _latitude,
      longitude: _longitude,
      customImageBase64: _customImageBase64,
      landUnit: _selectedLandUnit,
      landUnitValue: double.tryParse(_landUnitValueController.text),
      agent: const Agent(
        id: 'user_agent',
        name: 'Murugan N (You)',
        agencyName: 'Direct Owner',
        phone: '+91 98401 98765',
        email: 'murugan.properties@gmail.com',
        avatarKey: 'avatar_user',
        rating: 5.0,
        reviewsCount: 12,
        experienceYears: 4,
        totalListings: 4,
        isVerified: true,
        about: 'Direct verified owner listing premium properties.',
      ),
      postedDate: DateTime.now(),
      status: 'active',
      isVerified: true,
      isFeatured: true,
      isUserPosted: true,
      views: 1,
      enquiries: 0,
    );

    // Persist property
    await ref.read(propertiesProvider.notifier).addProperty(newProp);

    // Add notification
    final storage = ref.read(localStorageServiceProvider);
    final notifs = storage.getNotifications();
    notifs.insert(
      0,
      NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Listing Published!',
        message: 'Your property "${newProp.title}" is now active in My Ads.',
        timestamp: DateTime.now(),
        type: 'ad_approved',
        propertyId: newProp.id,
      ),
    );
    await storage.saveNotifications(notifs);
    ref.read(notificationsProvider.notifier).refresh();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PostSuccessScreen(property: newProp),
        ),
      );
    }
  }

  void _showValidationToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
