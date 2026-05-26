// FILE: lib/features/products/widgets/add_category_sheet.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';

// ═══════════════════════════════════════════════════════════════
// ADD CATEGORY SHEET
//
// Single-step: type toggle + form in one sheet.
// Eliminates the two-step modal stack — faster for daily admin use.
// onCategoryCreated is optional (only used by the selector sheet).
// ═══════════════════════════════════════════════════════════════
class AddCategorySheet extends StatefulWidget {
  final CategoryController categoryC;
  final void Function(String newId)? onCategoryCreated;

  const AddCategorySheet({
    super.key,
    required this.categoryC,
    this.onCategoryCreated,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameC = TextEditingController();
  bool _isSubCategory = false;
  String? _selectedParentId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      _showError('Nama kategori harus diisi');
      return;
    }
    if (_isSubCategory && _selectedParentId == null) {
      _showError('Pilih kategori utama terlebih dahulu');
      return;
    }

    setState(() => _isSaving = true);

    final newId = await widget.categoryC.createCategory(
      name,
      parentId: _isSubCategory ? _selectedParentId : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (newId != null) {
      widget.onCategoryCreated?.call(newId);
      Get.back();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: const Color(0xFF3A3A3A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Title ──
          const Center(
            child: Text(
              'Tambah Kategori',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),

          // ── Type toggle ──
          _TypeToggle(
            isSubCategory: _isSubCategory,
            onChanged: (value) => setState(() {
              _isSubCategory = value;
              // Reset parent selection when switching type
              _selectedParentId = null;
            }),
          ),
          const SizedBox(height: 16),

          // ── Parent dropdown (only when sub-category) ──
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: _isSubCategory
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Masuk ke dalam'),
                      const SizedBox(height: 6),
                      Obx(() {
                        final parents = widget.categoryC.parentCategories;
                        return DropdownButtonFormField<String>(
                          value: _selectedParentId,
                          hint: Text(
                            'Pilih kategori utama',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade400),
                          ),
                          items: parents
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name,
                                        style:
                                            const TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedParentId = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColors.primary.withAlpha(80),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Colors.white,
                        );
                      }),
                      const SizedBox(height: 14),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Category name ──
          _FieldLabel(_isSubCategory ? 'Nama Sub-Kategori' : 'Nama Kategori'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameC,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  _isSubCategory ? 'cth: Minuman Soda' : 'cth: Makanan',
              hintStyle:
                  TextStyle(fontSize: 14, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.primary.withAlpha(80),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),

          // ── Save button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type toggle ─────────────────────────────────────────────────
//
// Segmented-style toggle: cleaner than two big option tiles
// for a binary choice with no complex descriptions needed.
// ─────────────────────────────────────────────────────────────────
class _TypeToggle extends StatelessWidget {
  final bool isSubCategory;
  final void Function(bool) onChanged;

  const _TypeToggle({
    required this.isSubCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Kategori Utama',
            selected: !isSubCategory,
            isLeft: true,
            onTap: () => onChanged(false),
          ),
          _ToggleOption(
            label: 'Sub-kategori',
            selected: isSubCategory,
            isLeft: false,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.isLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.fromLTRB(
            isLeft ? 3 : 0,
            3,
            isLeft ? 0 : 3,
            3,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Field label ─────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.subtext,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}