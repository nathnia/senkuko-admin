import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/features/banners/banner_model.dart';
import 'package:senkukoadmin/features/banners/banner_service.dart';

class BannerController extends GetxController {
  // ===================== LIST STATE =====================
  final isLoading = false.obs;
  final bannerList = <BannerData>[].obs;
  final filteredBanners = <BannerData>[].obs;
  final searchText = ''.obs;
  final Rxn<bool> statusFilter = Rxn(null); // null = semua
  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ===================== FORM STATE =====================
  final isSubmitting = false.obs;
  final isDirty = false.obs;
  final titleC = TextEditingController();
  final sortOrderC = TextEditingController(text: '0');
  final isActive = true.obs;
  final Rxn<File> pickedImage = Rxn(null);
  String _existingImageUrl = '';
  String get existingImageUrl => _existingImageUrl;

  // Snapshot untuk edit dirty tracking
  String _snapTitle = '';
  String _snapSortOrder = '0';
  bool _snapActive = true;

  List<TextEditingController> get _formControllers => [titleC, sortOrderC];

  // ===================== LIFECYCLE =====================
  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    if (!_hasLoadedOnce) {
      fetchBanners();
      _hasLoadedOnce = true;
    }
  }

  /// Dipanggil dari pull-to-refresh — selalu maksa network call, skip cache.
  Future<void> refreshBanners() => fetchBanners(forceRefresh: true);

  @override
  void onClose() {
    for (final c in _formControllers) {
      c.dispose();
    }
    super.onClose();
  }

  // ===================== IMAGE PICKER =====================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      pickedImage.value = File(file.path);
      isDirty.value = true;
    }
  }

  // ===================== SORT ORDER HELPERS =====================
  int get _nextSortOrder {
    if (bannerList.isEmpty) return 0;
    return bannerList.map((b) => b.sortOrder).reduce((a, b) => a > b ? a : b) +
        1;
  }

  bool _isDuplicateSortOrder(int order, {String? excludeId}) {
    return bannerList.any(
      (b) => b.sortOrder == order && b.id != excludeId,
    );
  }

  // ===================== FORM HELPERS =====================
  void _removeListeners(VoidCallback fn) {
    for (final c in _formControllers) {
      c.removeListener(fn);
    }
  }

  void _addListeners(VoidCallback fn) {
    for (final c in _formControllers) {
      c.addListener(fn);
    }
  }

  void _checkAddDirty() {
    isDirty.value = pickedImage.value != null;
  }

  void _checkEditDirty() {
    isDirty.value =
        titleC.text.trim() != _snapTitle ||
        sortOrderC.text.trim() != _snapSortOrder ||
        isActive.value != _snapActive ||
        pickedImage.value != null;
  }

  void toggleActive(bool val) {
    isActive.value = val;
    _checkEditDirty();
  }

  void resetForAdd() {
    _removeListeners(_checkAddDirty);
    _removeListeners(_checkEditDirty);
    for (final c in _formControllers) {
      c.clear();
    }
    sortOrderC.text = _nextSortOrder.toString();
    isActive.value = true;
    pickedImage.value = null;
    _existingImageUrl = '';
    isDirty.value = false;
    isSubmitting.value = false;

    _addListeners(_checkAddDirty);
  }

  void resetForEdit() {
    _removeListeners(_checkAddDirty);
    _removeListeners(_checkEditDirty);
    for (final c in _formControllers) {
      c.clear();
    }
    isActive.value = true;
    pickedImage.value = null;
    _existingImageUrl = '';
    isDirty.value = false;
    isSubmitting.value = false;
  }

  void populateEditForm(BannerData b) {
    _snapTitle = b.title ?? '';
    _snapSortOrder = b.sortOrder.toString();
    _snapActive = b.isActive;

    titleC.text = _snapTitle;
    sortOrderC.text = _snapSortOrder;
    isActive.value = _snapActive;
    pickedImage.value = null;
    _existingImageUrl = b.imageUrl;
    isDirty.value = false;

    _addListeners(_checkEditDirty);
  }

  // ===================== FILTER =====================
  void _applyFilter() {
    final lower = searchText.value.trim().toLowerCase();
    filteredBanners.assignAll(
      bannerList.where((b) {
        final matchStatus =
            statusFilter.value == null || b.isActive == statusFilter.value;
        final matchSearch =
            lower.isEmpty || (b.title?.toLowerCase().contains(lower) ?? false);
        return matchStatus && matchSearch;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void setStatusFilter(String label) {
    switch (label) {
      case 'Aktif':
        statusFilter.value = true;
        break;
      case 'Nonaktif':
        statusFilter.value = false;
        break;
      default:
        statusFilter.value = null;
        break;
    }
    _applyFilter();
  }

  String get statusFilterLabel {
    if (statusFilter.value == true) return 'Aktif';
    if (statusFilter.value == false) return 'Nonaktif';
    return 'Semua';
  }

  // ===================== FETCH =====================
  // CHANGED: dari staleness-only (in-memory) jadi full CacheService
  // (Pola A, sama kayak CategoryController/UnitController). Banner masuk
  // kategori reference data — jarang berubah, gak kritis kalau agak basi,
  // dan ada pull-to-refresh sebagai manual override. TTL panjang
  // (referenceDataTtl = 1 jam) BENERAN skip network call kalau masih
  // fresh, beda sama allVariants/priceList yang instant-paint doang.
  Future<void> fetchBanners({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.banners,
        ttl: CacheKeys.referenceDataTtl,
      );
      if (cached != null) {
        // FIX: paksa jalur cache-hit gak pernah 100% sinkron — nyegah
        // crash "setState()/markNeedsBuild() called during build" kalau
        // dipanggil dari initState() page. Lihat CategoryController
        // buat penjelasan lengkap.
        await Future.microtask(() {});
        bannerList.assignAll(
          (cached as List).map((e) => BannerData.fromJson(e)).toList(),
        );
        _applyFilter();
        return; // cache masih valid, skip network sepenuhnya
      }
    }

    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final res = await BannerService.getAllBanners();
      if (res.statusCode == 200) {
        final list = bannerModelFromJson(res.body).data;
        bannerList.assignAll(list);
        _applyFilter();
        await CacheService.instance.set(
          CacheKeys.banners,
          list.map((b) => b.toJson()).toList(),
        );
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar banner.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data.';
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createBanner() async {
    if (!_validateForm(isAdd: true)) return false;

    final order = int.tryParse(sortOrderC.text.trim()) ?? 0;
    if (_isDuplicateSortOrder(order)) {
      final proceed = await AppDialog.confirm(
        title: 'Urutan Sudah Dipakai',
        content:
            'Urutan $order sudah dipakai banner lain. Lanjut simpan? '
            'Urutan tampil bisa jadi tidak berurutan.',
        confirmLabel: 'Lanjut Simpan',
        confirmColor: AppColors.primary,
      );
      if (!proceed) return false;
    }

    isSubmitting.value = true;
    try {
      final res = await BannerService.createBanner(
        image: pickedImage.value!,
        title: titleC.text.trim().isEmpty ? null : titleC.text.trim(),
        sortOrder: int.tryParse(sortOrderC.text.trim()),
        isActive: isActive.value,
      );

      if (res.statusCode == 201) {
        // Invalidate + forceRefresh — biar admin yang sama langsung lihat
        // banner barunya sendiri, gak nunggu TTL 1 jam abis.
        await CacheService.instance.invalidate(CacheKeys.banners);
        await fetchBanners(forceRefresh: true);
        AppToast.show('Banner berhasil ditambahkan');
        resetForAdd();
        return true;
      } else {
        AppToast.show(
          ApiHelper.parseError(res.body, 'Gagal menambahkan banner'),
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error createBanner: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updateBanner(String id) async {
    if (!_validateForm(isAdd: false)) return false;

    final order = int.tryParse(sortOrderC.text.trim()) ?? 0;
    if (_isDuplicateSortOrder(order, excludeId: id)) {
      final proceed = await AppDialog.confirm(
        title: 'Urutan Sudah Dipakai',
        content:
            'Urutan $order sudah dipakai banner lain. Lanjut simpan? '
            'Urutan tampil bisa jadi tidak berurutan.',
        confirmLabel: 'Lanjut Simpan',
        confirmColor: AppColors.primary,
      );
      if (!proceed) return false;
    }

    isSubmitting.value = true;
    try {
      final body = <String, dynamic>{
        'title': titleC.text.trim(),
        'sort_order': int.tryParse(sortOrderC.text.trim()) ?? 0,
        'is_active': isActive.value ? 1 : 0,
      };

      final res = await BannerService.updateBanner(id, body);

      if (res.statusCode != 200) {
        AppToast.show(
          ApiHelper.parseError(res.body, 'Gagal memperbarui banner'),
        );
        return false;
      }

      // Kalau user pilih gambar baru, upload sekarang
      if (pickedImage.value != null) {
        final imgRes = await BannerService.updateBannerImage(
          id,
          pickedImage.value!,
        );
        if (imgRes.statusCode != 200) {
          AppToast.show('Data tersimpan, tapi gagal mengganti gambar');
        }
      }

      // Invalidate + forceRefresh — sekali fetch ulang dari server biar
      // list ke-sync penuh (title, sort_order, is_active, DAN url gambar
      // baru kalau ada), sekaligus refresh cache-nya.
      await CacheService.instance.invalidate(CacheKeys.banners);
      await fetchBanners(forceRefresh: true);
      AppToast.show('Banner berhasil diperbarui');
      return true;
    } catch (e) {
      debugPrint('Error updateBanner: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== TOGGLE STATUS =====================
  Future<bool> toggleBannerStatus(BannerData banner) async {
    final newStatus = !banner.isActive;
    final label = newStatus ? 'aktifkan' : 'nonaktifkan';

    final confirmed = await AppDialog.confirm(
      title: '${newStatus ? 'Aktifkan' : 'Nonaktifkan'} Banner',
      content: 'Yakin ingin $label banner "${banner.title ?? banner.id}"?',
      confirmLabel: newStatus ? 'Aktifkan' : 'Nonaktifkan',
      confirmColor: newStatus ? Colors.green : Colors.orange,
    );

    if (!confirmed) return false;

    isLoading.value = true;
    try {
      final res = await BannerService.updateBanner(banner.id, {
        'is_active': newStatus ? 1 : 0,
      });
      if (res.statusCode == 200) {
        await CacheService.instance.invalidate(CacheKeys.banners);
        await fetchBanners(forceRefresh: true);
        AppToast.show(newStatus ? 'Banner diaktifkan' : 'Banner dinonaktifkan');
        return true;
      }
      AppToast.show('Gagal mengubah status');
      return false;
    } catch (e) {
      debugPrint('Error toggleBannerStatus: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== DELETE =====================
  Future<bool> deleteBanner(BannerData banner) async {
    final confirmed = await AppDialog.confirm(
      title: 'Hapus Banner',
      content: 'Yakin ingin menghapus banner "${banner.title ?? banner.id}"? '
          'Tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'Hapus',
      confirmColor: Colors.red,
    );

    if (!confirmed) return false;

    isLoading.value = true;
    try {
      final res = await BannerService.deleteBanner(banner.id);
      if (res.statusCode == 200) {
        await CacheService.instance.invalidate(CacheKeys.banners);
        await fetchBanners(forceRefresh: true);
        AppToast.show('Banner berhasil dihapus');
        return true;
      }
      AppToast.show(ApiHelper.parseError(res.body, 'Gagal menghapus banner'));
      return false;
    } catch (e) {
      debugPrint('Error deleteBanner: $e');
      AppToast.show('Terjadi kesalahan');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== VALIDATION =====================
  bool _validateForm({required bool isAdd}) {
    if (isAdd && pickedImage.value == null) {
      AppToast.show('Gambar banner wajib dipilih');
      return false;
    }
    final sortOrderText = sortOrderC.text.trim();
    if (sortOrderText.isNotEmpty && int.tryParse(sortOrderText) == null) {
      AppToast.show('Urutan harus berupa angka');
      return false;
    }
    return true;
  }
}