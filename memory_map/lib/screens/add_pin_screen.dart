import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import 'add_visit_screen.dart';

class AddPinScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const AddPinScreen({super.key, this.initialLocation});

  @override
  State<AddPinScreen> createState() => _AddPinScreenState();
}

class _AddPinScreenState extends State<AddPinScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  Category _selectedCategory = Category.cafe;
  bool _isPrivate = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a place name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final loc = widget.initialLocation ??
        const LatLng(14.5547, 121.0244); // Default: BGC
    final userId = context.read<UserProvider>().user.id;

    final newPin = MapPin(
      id: const Uuid().v4(),
      userId: userId,
      lat: loc.latitude,
      lng: loc.longitude,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      address: _addressController.text.trim().isEmpty
          ? 'Manila, Philippines'
          : _addressController.text.trim(),
      isPrivate: _isPrivate,
      createdAt: DateTime.now(),
      visits: [],
      rating: 0,
      priceRange: PriceRange.moderate,
      bestItems: [],
    );

    if (!mounted) return;
    await context.read<PinsProvider>().addPin(newPin);
    setState(() => _isSaving = false);

    if (!mounted) return;
    // Now open AddVisitScreen for the first visit
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, scrollCtrl) => AddVisitScreen(
          pinId: newPin.id,
          pinName: newPin.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.initialLocation ?? const LatLng(14.5547, 121.0244);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.add_location, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 8),
                const Text(
                  'Add New Place',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A535C),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location display
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A535C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1A535C).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFFFF6B6B), size: 20),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pin Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1A535C),
                              ),
                            ),
                            Text(
                              '${loc.latitude.toStringAsFixed(4)}°N, '
                              '${loc.longitude.toStringAsFixed(4)}°E',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Place name
                  _SectionLabel(label: 'Place Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration('e.g., Toby\'s Estate BGC'),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _SectionLabel(label: 'Address'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration:
                        _inputDecoration('e.g., High Street, BGC, Taguig'),
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _SectionLabel(label: 'Category'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: Category.values.map((cat) {
                      final sel = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: sel
                                ? cat.color.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? cat.color : Colors.grey.shade200,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: sel ? cat.color : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Private toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline,
                            color: Color(0xFF9B59B6), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Private Pin',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Only visible to you',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPrivate,
                          onChanged: (v) => setState(() => _isPrivate = v),
                          activeColor: const Color(0xFF1A535C),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _proceed,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.navigate_next,
                              color: Colors.white),
                      label: const Text(
                        'Next: Log Visit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A535C)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: Color(0xFF1A535C),
        letterSpacing: 0.3,
      ),
    );
  }
}
