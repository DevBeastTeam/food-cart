import 'package:flutter/material.dart';
import '../models/daig_item.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';
import 'custom_image.dart';

class DaigCard extends StatefulWidget {
  final DaigItem daig;
  final CartState cartState;

  const DaigCard({
    super.key,
    required this.daig,
    required this.cartState,
  });

  @override
  State<DaigCard> createState() => _DaigCardState();
}

class _DaigCardState extends State<DaigCard> {
  void _openBookingSheet() {
    String selectedSize = 'large'; // 'small', 'medium', 'large'
    int degQuantity = 1;
    String selectedOccasion = 'Dawat / Gathering';
    String selectedSpiceLevel = 'Normal Dum';
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final double unitPrice;
            final String sizeLabel;
            final String servingLabel;

            if (selectedSize == 'small') {
              unitPrice = widget.daig.halfDaigPrice;
              sizeLabel = 'Small (6 KG)';
              servingLabel = 'Serves 15–20 Persons';
            } else if (selectedSize == 'medium') {
              unitPrice = widget.daig.mediumDaigPrice;
              sizeLabel = 'Medium (10 KG)';
              servingLabel = 'Serves 25–30 Persons';
            } else {
              unitPrice = widget.daig.fullDaigPrice;
              sizeLabel = 'Large (12–14 KG)';
              servingLabel = 'Serves 35–45 Persons';
            }

            final totalPrice = unitPrice * degQuantity;

            return Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(ctx).size.height * 0.08,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title & Close Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E1065).withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🍲 AUTHENTIC DEGI ORDER',
                                        style: TextStyle(
                                          color: Color(0xFF4C1D95),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.daig.badge,
                                      style: TextStyle(
                                        color: Colors.amber.shade800,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.daig.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.daig.urduName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 22),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.daig.description,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 12),

                      // STEP 1: SELECT DEGI SIZE
                      const Text(
                        '1. Choose Daig Size & Capacity (دیگ کا سائز)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Large Daig Option
                      _buildSizeOption(
                        title: 'Large / Full Daig (12–14 KG Basmati & Meat)',
                        serving: 'Serves 35–45 Persons • Grand Wedding / Feast',
                        price: widget.daig.fullDaigPrice,
                        isSelected: selectedSize == 'large',
                        onTap: () => setModalState(() => selectedSize = 'large'),
                      ),

                      const SizedBox(height: 8),

                      // Medium Daig Option
                      _buildSizeOption(
                        title: 'Medium / Standard Daig (10 KG Basmati & Meat)',
                        serving: 'Serves 25–30 Persons • Family Dawat / Event',
                        price: widget.daig.mediumDaigPrice,
                        isSelected: selectedSize == 'medium',
                        onTap: () => setModalState(() => selectedSize = 'medium'),
                      ),

                      const SizedBox(height: 8),

                      // Small Daig Option
                      _buildSizeOption(
                        title: 'Small / Half Daig (6 KG Basmati & Meat)',
                        serving: 'Serves 15–20 Persons • Small Gathering / Khatam',
                        price: widget.daig.halfDaigPrice,
                        isSelected: selectedSize == 'small',
                        onTap: () => setModalState(() => selectedSize = 'small'),
                      ),

                      const SizedBox(height: 18),

                      // STEP 2: QUANTITY OF DEGS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '2. Number of Degs (دیگوں کی تعداد)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$degQuantity x $sizeLabel ($servingLabel)',
                                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: degQuantity > 1
                                      ? () => setModalState(() => degQuantity--)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    '$degQuantity Deg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4C1D95),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: degQuantity < 10
                                      ? () => setModalState(() => degQuantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // STEP 3: OCCASION
                      const Text(
                        '3. Event / Occasion (تقریب)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Dawat / Gathering',
                          'Wedding / Walima',
                          'Niaz / Milad / Khatam',
                          'Office Event',
                        ].map((occ) {
                          final isSel = selectedOccasion == occ;
                          return ChoiceChip(
                            label: Text(occ),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedOccasion = occ);
                            },
                            selectedColor: const Color(0xFF2E1065).withAlpha(25),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF4C1D95) : AppTheme.textPrimary,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // STEP 4: SPICE & COOKING CUSTOMIZATION
                      const Text(
                        '4. Spice Dum Level (مرچ کا لیول)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'Mild Dum',
                          'Normal Dum',
                          'Extra Spicy Potli Dum',
                        ].map((spice) {
                          final isSel = selectedSpiceLevel == spice;
                          return ChoiceChip(
                            label: Text(spice),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedSpiceLevel = spice);
                            },
                            selectedColor: Colors.orange.shade50,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.deepOrange : AppTheme.textPrimary,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Included Extras
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                                SizedBox(width: 6),
                                Text(
                                  'Included Free with this Daig Order:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...widget.daig.includes.map(
                              (inc) => Padding(
                                padding: const EdgeInsets.only(left: 22, bottom: 3),
                                child: Text('• $inc', style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563))),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Special Instructions
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Notes: e.g. Extra aloo, arrival at 1:30 PM lunch, or specific delivery instructions...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            final foodItem = widget.daig.toFoodItem(
                              sizeName: selectedSize,
                              occasion: selectedOccasion,
                              notes: 'Spice: $selectedSpiceLevel${notesController.text.trim().isNotEmpty ? " • ${notesController.text.trim()}" : ""}',
                            );

                            for (int i = 0; i < degQuantity; i++) {
                              widget.cartState.addItem(
                                foodItem,
                                widget.daig.centerId,
                                widget.daig.centerName,
                              );
                            }
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added $degQuantity x ${foodItem.name} to Cart!',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF4C1D95),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C1D95),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Book $degQuantity Daig ($sizeLabel)',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rs. ${totalPrice.toInt()}',
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSizeOption({
    required String title,
    required String serving,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withAlpha(80) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    serving,
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              'Rs. ${price.toInt()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CustomImage(
                  imageUrl: widget.daig.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E).withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.outdoor_grill_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 5),
                      Text(
                        widget.daig.badge,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.daig.rating}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.daig.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      widget.daig.urduName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.daig.description,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Serving Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Full: 12 KG (Serves 35-40)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Half: 6 KG (Serves 18-20)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),

                // Price and Order Deg Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price per Daig',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${widget.daig.fullDaigPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openBookingSheet,
                      icon: const Icon(Icons.soup_kitchen_rounded, size: 15),
                      label: const Text('Book Daig'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
