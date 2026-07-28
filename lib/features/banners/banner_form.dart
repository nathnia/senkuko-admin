import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/constant/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/banners/banner_controller.dart';
import 'package:senkukoadmin/features/banners/banner_model.dart';

enum BannerFormMode { add, edit }

class BannerFormPage extends StatefulWidget {
  const BannerFormPage({super.key});

  @override
  State<BannerFormPage> createState() => _BannerFormPageState();
}

class _BannerFormPageState extends State<BannerFormPage> {
  late final BannerController _c;
  late final BannerFormMode _mode;
  BannerData? _banner;

  @override
  void initState() {
    super.initState();
    _c = Get.find<BannerController>();

    final args = Get.arguments;
    if (args is BannerData) {
      _mode = BannerFormMode.edit;
      _banner = args;
      _c.populateEditForm(args);
    } else {
      _mode = BannerFormMode.add;
      _c.resetForAdd();
    }
  }

  bool get _isEdit => _mode == BannerFormMode.edit;

  Future<bool> _onWillPop() async {
    if (!_c.isDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  Future<void> _onSubmit() async {
    final bool ok;
    if (_isEdit) {
      ok = await _c.updateBanner(_banner!.id);
    } else {
      ok = await _c.createBanner();
    }
    if (ok && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop) Get.back();
            },
          ),
          title: Text(
            _isEdit ? 'Edit Banner' : 'Tambah Banner',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: _StickyButton(
          c: _c,
          isEdit: _isEdit,
          onSubmit: _onSubmit,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              _ImagePicker(c: _c),
              const SizedBox(height: 12),

              AppCard(
                title: 'INFORMASI BANNER',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _c.titleC,
                      label: 'Judul',
                      hint: 'Contoh: Promo Akhir Tahun',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    AppTextField(
                      controller: _c.sortOrderC,
                      label: 'Urutan Tampil',
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                    Obx(
                      () => _ActiveSwitch(
                        value: _c.isActive.value,
                        onChanged: _isEdit
                            ? _c.toggleActive
                            : (val) => _c.isActive.value = val,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image picker ──────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  final BannerController c;
  const _ImagePicker({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final picked = c.pickedImage.value;
      final existingUrl = c.existingImageUrl;

      Widget preview;
      if (picked != null) {
        preview = Image.file(picked, fit: BoxFit.cover);
      } else if (existingUrl.isNotEmpty) {
        preview = Image.network(
          existingUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emptyState(),
        );
      } else {
        preview = _emptyState();
      }

      return InkWell(
        onTap: c.pickImage,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              preview,
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(140),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _emptyState() {
    return Container(
      color: AppColors.successBg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih Gambar Banner',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active switch row ─────────────────────────────────────────────────────

class _ActiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ActiveSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Status Aktif',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Sticky submit button ──────────────────────────────────────────────────

class _StickyButton extends StatelessWidget {
  final BannerController c;
  final bool isEdit;
  final VoidCallback onSubmit;

  const _StickyButton({
    required this.c,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: c.isSubmitting.value || !c.isDirty.value
                  ? null
                  : onSubmit,
              child: c.isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEdit ? 'Simpan Perubahan' : 'Simpan Banner',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
