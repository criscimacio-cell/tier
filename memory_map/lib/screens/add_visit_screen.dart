import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/mood_chip.dart';
import '../widgets/star_rating.dart';

class AddVisitScreen extends StatefulWidget {
  final String pinId;
  final String pinName;

  const AddVisitScreen({
    super.key,
    required this.pinId,
    required this.pinName,
  });

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  DateTime _selectedDate = DateTime.now();
  double _rating = 4.0;
  PriceRange _priceRange = PriceRange.moderate;
  Mood _mood = Mood.cozy;
  final _reviewController = TextEditingController();
  final _journalController = TextEditingController();
  final _bestItemController = TextEditingController();
  final List<String> _bestItems = [];
  final List<XFile> _pickedImages = [];
  bool _isSaving = false;
  String _saveStatus = '';

  final _picker = ImagePicker();

  @override
  void dispose() {
    _reviewController.dispose();
    _journalController.dispose();
    _bestItemController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF6366F1)),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Select multiple photos'),
              onTap: () async {
                Navigator.pop(context);
                final imgs = await _picker.pickMultiImage(imageQuality: 80);
                if (imgs.isNotEmpty) {
                  setState(() => _pickedImages.addAll(imgs));
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFFF43F5E)),
              ),
              title: const Text('Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Use your camera'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (img != null) {
                  setState(() => _pickedImages.add(img));
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _addBestItem() {
    final text = _bestItemController.text.trim();
    if (text.isNotEmpty && !_bestItems.contains(text)) {
      setState(() {
        _bestItems.add(text);
        _bestItemController.clear();
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveStatus = _pickedImages.isNotEmpty ? 'Uploading photos...' : '';
    });

    final visitId = const Uuid().v4();
    final userId = context.read<UserProvider>().user.id;

    // Upload photos first
    List<String> photoUrls = [];
    for (final img in _pickedImages) {
      setState(() => _saveStatus =
          'Uploading photo ${_pickedImages.indexOf(img) + 1} of ${_pickedImages.length}...');
      final url = await SupabaseService()
          .uploadVisitPhoto(img.path, userId, visitId);
      if (url != null) photoUrls.add(url);
    }

    setState(() => _saveStatus = 'Saving visit...');

    final visit = Visit(
      id: visitId,
      date: _selectedDate,
      review: _reviewController.text.trim(),
      mood: _mood,
      photoUrls: photoUrls,
      journalEntry: _journalController.text.trim(),
      taggedFriends: [],
    );

    if (!mounted) return;
    final pinsProvider = context.read<PinsProvider>();
    final userProvider = context.read<UserProvider>();

    await pinsProvider.addVisit(widget.pinId, visit);
    userProvider.updateStreak();
    userProvider.checkAndAwardBadges(
      pinsProvider.pins.length,
      pinsProvider.totalVisits,
    );

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.add_location_alt_rounded, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log a Visit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      Text(
                        widget.pinName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section: When & Vibe ────────────────────────────────
                  _SectionCard(
                    children: [
                      // Date
                      GestureDetector(
                        onTap: _pickDate,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month_rounded,
                                  color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date visited',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    DateFormat('EEEE, MMMM d, yyyy')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                      const Divider(height: 24),

                      // Mood
                      const Text('Vibe',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1))),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Mood.values.map((m) {
                          return MoodChip(
                            mood: m,
                            selected: _mood == m,
                            onTap: () => setState(() => _mood = m),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Section: Rating & Price ─────────────────────────────
                  _SectionCard(
                    children: [
                      const Text('Rating',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1))),
                      const SizedBox(height: 12),
                      Center(
                        child: InteractiveStarRating(
                          initialRating: _rating,
                          onRatingChanged: (r) => setState(() => _rating = r),
                        ),
                      ),
                      const Divider(height: 24),
                      const Text('Price Range',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1))),
                      const SizedBox(height: 10),
                      Row(
                        children: PriceRange.values.map((pr) {
                          final sel = _priceRange == pr;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _priceRange = pr),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF6366F1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF6366F1)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    pr.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Section: Photos ─────────────────────────────────────
                  _SectionCard(
                    children: [
                      Row(
                        children: [
                          const Text('Photos',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                          const Spacer(),
                          Text('optional',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_pickedImages.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              if (i == _pickedImages.length) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          style: BorderStyle.solid),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_rounded,
                                            color: Colors.grey.shade400,
                                            size: 28),
                                        const SizedBox(height: 4),
                                        Text('Add more',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_pickedImages[i].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _pickedImages.removeAt(i)),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 4),
                      ] else ...[
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade200,
                                  style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_rounded,
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                    size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap to add photos from gallery or camera',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Section: Review & Notes ─────────────────────────────
                  _SectionCard(
                    children: [
                      Row(
                        children: [
                          const Text('Quick Review',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                          const Spacer(),
                          Text('optional',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reviewController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                            'What stood out? What\'s worth ordering?'),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Text('Personal Notes',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Private',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFA855F7),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _journalController,
                        maxLines: 4,
                        decoration: _inputDecoration(
                            'How did this place make you feel? What memories were made here...'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Section: Best Items ─────────────────────────────────
                  _SectionCard(
                    children: [
                      Row(
                        children: [
                          const Text('Must-Try Items',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6366F1))),
                          const Spacer(),
                          Text('optional',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_bestItems.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _bestItems.map((item) {
                            return Chip(
                              label: Text(item),
                              onDeleted: () =>
                                  setState(() => _bestItems.remove(item)),
                              backgroundColor: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.1),
                              deleteIconColor: const Color(0xFF6366F1),
                              labelStyle: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bestItemController,
                              decoration: _inputDecoration('e.g., Truffle Pasta'),
                              onSubmitted: (_) => _addBestItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addBestItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                                if (_saveStatus.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Text(_saveStatus,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ],
                            )
                          : const Text(
                              'Save Memory',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
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
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

