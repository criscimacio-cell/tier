import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/pins_provider.dart';
import '../providers/user_provider.dart';
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
  bool _showMockPhotos = false;
  final List<Color> _mockPhotoColors = [
    const Color(0xFFE8D5B7),
    const Color(0xFFB7D5E8),
    const Color(0xFFD5E8B7),
    const Color(0xFFE8B7D5),
  ];
  bool _isSaving = false;

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
            primary: Color(0xFF1A535C),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final visit = Visit(
      id: const Uuid().v4(),
      date: _selectedDate,
      review: _reviewController.text.trim(),
      mood: _mood,
      photoUrls: [],
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
        color: Color(0xFFF7F3E9),
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
                const Icon(Icons.add_location_alt, color: Color(0xFF1A535C)),
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
                          color: Color(0xFF1A535C),
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
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
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
                  // Date picker
                  _SectionLabel(label: 'When did you visit?'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF1A535C), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy')
                                .format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rating
                  _SectionLabel(label: 'How was it?'),
                  const SizedBox(height: 10),
                  Center(
                    child: InteractiveStarRating(
                      initialRating: _rating,
                      onRatingChanged: (r) => setState(() => _rating = r),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price range
                  _SectionLabel(label: 'Price Range'),
                  const SizedBox(height: 8),
                  Row(
                    children: PriceRange.values.map((pr) {
                      final sel = _priceRange == pr;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _priceRange = pr),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? const Color(0xFF1A535C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF1A535C)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                pr.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Mood
                  _SectionLabel(label: 'What was the vibe?'),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 20),

                  // Review
                  _SectionLabel(label: 'Quick Review'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'What stood out? What\'s worth ordering?',
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
                        borderSide:
                            const BorderSide(color: Color(0xFF1A535C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Journal entry
                  _SectionLabel(label: 'Journal Entry (Private)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _journalController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'How did this place make you feel? What memories were made here...',
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
                        borderSide:
                            const BorderSide(color: Color(0xFF1A535C)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Best items
                  _SectionLabel(label: 'Best Items (optional)'),
                  const SizedBox(height: 8),
                  if (_bestItems.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _bestItems.map((item) {
                        return Chip(
                          label: Text(item),
                          onDeleted: () =>
                              setState(() => _bestItems.remove(item)),
                          backgroundColor:
                              const Color(0xFF1A535C).withOpacity(0.1),
                          deleteIconColor: const Color(0xFF1A535C),
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A535C),
                            fontWeight: FontWeight.w500,
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
                          decoration: InputDecoration(
                            hintText: 'e.g., Truffle Pasta',
                            hintStyle:
                                TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A535C)),
                            ),
                          ),
                          onSubmitted: (_) => _addBestItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addBestItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A535C),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Photo placeholders
                  _SectionLabel(label: 'Photos'),
                  const SizedBox(height: 8),
                  if (_showMockPhotos) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _mockPhotoColors.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (_, i) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _mockPhotoColors[i],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(Icons.image,
                                color: Colors.white.withOpacity(0.5),
                                size: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _showMockPhotos = !_showMockPhotos),
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        color: Color(0xFF1A535C)),
                    label: Text(
                      _showMockPhotos ? 'Photos Added ✓' : 'Add Photos',
                      style: const TextStyle(color: Color(0xFF1A535C)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A535C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A535C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Memory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
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
