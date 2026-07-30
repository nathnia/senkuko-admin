import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_service.dart';

class PromotionController extends GetxController {
  // ===================== STATE =====================
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;

  // ===================== DATA =====================
  final promotionList = <PromotionData>[].obs;
  final filteredPromotions = <PromotionData>[].obs;
  final selectedPromotion = Rxn<PromotionData>();

  // ===================== PAGE STATE =====================
  final searchText = ''.obs;
  final selectedFilter = 'Aktif'.obs;

  final hasError = false.obs;
  final errorMessage = ''.obs;

  // ===================== PROMOTION FORM =====================
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  final descC = TextEditingController();
  final usageLimitC = TextEditingController();

  final validFrom = Rxn<DateTime>();
  final validTo = Rxn<DateTime>();

  final selectedType = ''.obs;
  final isActive = true.obs;
  final stackable = false.obs;

  // Reset Form
  void resetForm() {
    nameC.clear();
    codeC.clear();
    descC.clear();
    usageLimitC.clear();
    validFrom.value = null;
    validTo.value = null;
    selectedType.value = '';
    isActive.value = true;
    stackable.value = false;

    isDirty.value = false;
    _takeSnapshot();
    _listenFormChanges();
  }

  // Load dari existing promotion
  void loadFormFromPromotion(PromotionData p) {
    nameC.text = p.name;
    codeC.text = p.code;
    descC.text = p.description ?? '';
    usageLimitC.text = p.usageLimit.toString();
    validFrom.value = p.validFrom;
    validTo.value = p.validTo;
    selectedType.value = p.type;
    isActive.value = p.isActive;
    stackable.value = p.stackable;

    isDirty.value = false;
    _takeSnapshot();
    _listenFormChanges();
  }

  // ===================== CONDITION FORM =====================
  final conditionType = ''.obs;
  final conditionOperator = ''.obs;
  final conditionValueC = TextEditingController();
  final conditionTargetIdC = TextEditingController();

  bool conditionNeedsTargetId(String type) =>
      type == 'specific_product' || type == 'specific_category';

  // ===================== REWARD FORM =====================
  final rewardType = ''.obs;
  final discountMode = ''.obs;
  final discountValueC = TextEditingController();
  final maxDiscountC = TextEditingController(text: '0');
  final freeVariantIdC = TextEditingController();
  final freeQtyC = TextEditingController(text: '1');

  // ===================== LIFECYCLE =====================
  bool _hasLoadedOnce = false;

  @override
  void onInit() {
    super.onInit();
    if (!_hasLoadedOnce) {
      fetchPromotions();
      _hasLoadedOnce = true;
    }
  }

  bool _initialized = false;

  /// Dipanggil dari PromotionPage.initState(). Controller-nya permanent,
  /// jadi tanpa ini searchText/selectedFilter bakal "nempel" dari sesi
  /// sebelumnya tiap halaman dibuka ulang — sama pattern-nya kayak
  /// VoucherController.initPage().
  void initPage() {
    if (_initialized) return;
    _initialized = true;
    resetPageState();
    refreshIfStale();
  }

  void resetInit() => _initialized = false;

  void resetPageState() {
    searchText.value = '';
    selectedFilter.value = 'Aktif';
    _applyFilter();
  }

  @override
  void onClose() {
    for (final c in [nameC, codeC, descC, usageLimitC]) {
      c.removeListener(checkDirty);
      c.dispose();
    }
    _typeWorker?.dispose();
    _validFromWorker?.dispose();
    _validToWorker?.dispose();
    _isActiveWorker?.dispose();
    _stackableWorker?.dispose();
    _rewardTypeWorker?.dispose();
    _discountModeWorker?.dispose();
    _conditionTypeWorker?.dispose();
    _conditionOperatorWorker?.dispose();

    discountValueC.removeListener(_checkRewardDirty);
    freeVariantIdC.removeListener(_checkRewardDirty);
    conditionValueC.removeListener(_checkConditionDirty);

    discountValueC.dispose();
    freeVariantIdC.dispose();
    conditionValueC.dispose();
    conditionTargetIdC.dispose();
    maxDiscountC.dispose();
    freeQtyC.dispose();

    super.onClose();
  }

  final isRewardFormDirty = false.obs;
  final isConditionFormDirty = false.obs;

  void _checkRewardDirty() {
    if (rewardType.value.isEmpty) {
      isRewardFormDirty.value = false;
      return;
    }
    isRewardFormDirty.value = rewardType.value == 'free_item'
        ? freeVariantIdC.text.trim().isNotEmpty
        : discountValueC.text.trim().isNotEmpty ||
              discountMode.value.isNotEmpty;
  }

  void _checkConditionDirty() {
    isConditionFormDirty.value =
        conditionType.value.isNotEmpty ||
        conditionOperator.value.isNotEmpty ||
        conditionValueC.text.trim().isNotEmpty;
  }

  void resetRewardForm({String? defaultType}) {
    rewardType.value = defaultType ?? '';
    discountMode.value = '';
    discountValueC.clear();
    maxDiscountC.text = '0';
    freeVariantIdC.clear();
    freeQtyC.text = '1';
    isRewardFormDirty.value = false;
    _listenRewardFormChanges();
  }

  void resetConditionForm() {
    conditionType.value = '';
    conditionOperator.value = '';
    conditionValueC.clear();
    conditionTargetIdC.clear();
    isConditionFormDirty.value = false;
    _listenConditionFormChanges();
  }

  Worker? _rewardTypeWorker;
  Worker? _discountModeWorker;
  Worker? _conditionTypeWorker;
  Worker? _conditionOperatorWorker;

  void _listenRewardFormChanges() {
    discountValueC.removeListener(_checkRewardDirty);
    freeVariantIdC.removeListener(_checkRewardDirty);
    discountValueC.addListener(_checkRewardDirty);
    freeVariantIdC.addListener(_checkRewardDirty);

    _rewardTypeWorker?.dispose();
    _discountModeWorker?.dispose();
    _rewardTypeWorker = ever(rewardType, (_) => _checkRewardDirty());
    _discountModeWorker = ever(discountMode, (_) => _checkRewardDirty());
  }

  void _listenConditionFormChanges() {
    conditionValueC.removeListener(_checkConditionDirty);
    conditionValueC.addListener(_checkConditionDirty);

    _conditionTypeWorker?.dispose();
    _conditionOperatorWorker?.dispose();
    _conditionTypeWorker = ever(conditionType, (_) => _checkConditionDirty());
    _conditionOperatorWorker = ever(
      conditionOperator,
      (_) => _checkConditionDirty(),
    );
  }

  // ===================== FILTER =====================
  void _applyFilter() {
    filteredPromotions.assignAll(
      promotionList.where((p) {
        final matchFilter = switch (selectedFilter.value) {
          'Aktif' => p.isValid,
          'Tidak Aktif' => !p.isActive,
          'Kedaluwarsa' => p.isExpired,
          _ => true,
        };
        final q = searchText.value.toLowerCase();
        final matchSearch =
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q);
        return matchFilter && matchSearch;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void updateFilter(String value) {
    selectedFilter.value = value;
    _applyFilter();
  }

  // ===================== STALENESS (TTL) =====================
  // Dipakai supaya list promo tetap kerasa "hidup" walau controller-nya
  // permanent — kalau admin lain nambah/edit promo dari device lain,
  // admin di device ini tetap bakal lihat update tanpa perlu keluar-masuk
  // halaman (yang gak akan trigger fetch lagi karena onInit cuma sekali).
  //
  // TTL 30 detik dipilih karena Promotion bukan data yang berubah tiap
  // detik (beda dari Transaction yang lebih realtime-sensitive) — cukup
  // buat nutup celah staleness tanpa bikin network call sia-sia.
  DateTime? _lastFetchedAt;
  static const _staleAfter = Duration(seconds: 30);

  bool get _isStale =>
      _lastFetchedAt == null ||
      DateTime.now().difference(_lastFetchedAt!) > _staleAfter;

  /// Panggil ini dari initState()/didChangeAppLifecycleState() halaman
  /// PromotionPage — BUKAN dari onInit controller (karena onInit cuma
  /// jalan sekali seumur controller, sementara ini perlu dicek tiap kali
  /// halaman dibuka/resume).
  void refreshIfStale() {
    if (_isStale) fetchPromotions();
  }

  // ===================== FETCH =====================
  Future<void> fetchPromotions() async {
    if (isLoading.value) return;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    try {
      final res = await PromotionService.getAllPromotions();
      if (res.statusCode == 200) {
        promotionList.assignAll(promotionListModelFromJson(res.body).data);
        _applyFilter();
        _lastFetchedAt = DateTime.now();
      } else {
        hasError.value = true;
        errorMessage.value = ApiHelper.isNetworkError(res)
            ? ApiHelper.parseError(res.body)
            : 'Gagal memuat daftar promosi.';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data.';
    } finally {
      isLoading.value = false;
    }
  }

  final hasDetailError = false.obs;
  final detailErrorMessage = ''.obs;

  Future<void> fetchPromotionById(String id) async {
    isLoadingDetail.value = true;
    hasDetailError.value = false;
    detailErrorMessage.value = '';
    selectedPromotion.value = null;
    try {
      final res = await PromotionService.getPromotionById(id);
      if (res.statusCode == 200) {
        selectedPromotion.value = PromotionData.fromJson(
          jsonDecode(res.body)['data'],
        );
        // Ensure product, category, variant names are available for tiles
        resolveConditionNames();
      } else {
        hasDetailError.value = true;
        detailErrorMessage.value = 'Gagal memuat detail promosi. Coba lagi.';
      }
    } catch (_) {
      hasDetailError.value = true;
      detailErrorMessage.value = 'Gagal memuat detail promosi. Coba lagi.';
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<bool> createPromotion() async {
    if (nameC.text.trim().isEmpty || codeC.text.trim().isEmpty) {
      AppToast.show('Nama dan Kode Promo harus diisi');
      return false;
    }
    if (validFrom.value == null || validTo.value == null) {
      AppToast.show('Periode berlaku harus diisi');
      return false;
    }
    if (selectedType.value.isEmpty) {
      AppToast.show('Tipe promosi harus dipilih');
      return false;
    }
    if (validFrom.value!.isAfter(validTo.value!)) {
      AppToast.show('Tanggal mulai tidak boleh setelah tanggal berakhir');
      return false;
    }
    isSubmitting.value = true;
    try {
      final res = await PromotionService.createPromotion(_buildPayload());
      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode != 200 && res.statusCode != 201) {
        AppToast.show(_parseError(res.body));
        return false;
      }
      AppToast.show('Promosi berhasil dibuat');
      await fetchPromotions();
      resetForm();
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat membuat promosi');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE =====================
  Future<bool> updatePromotion(String id) async {
    if (nameC.text.trim().isEmpty || codeC.text.trim().isEmpty) {
      AppToast.show('Nama dan Kode Promo harus diisi');
      return false;
    }
    if (validFrom.value == null || validTo.value == null) {
      AppToast.show('Periode berlaku harus diisi');
      return false;
    }
    isSubmitting.value = true;
    try {
      final res = await PromotionService.updatePromotion(id, _buildPayload());
      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return false;
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        AppToast.show(_parseError(res.body));
        return false;
      }
      AppToast.show('Promosi berhasil diperbarui');
      await fetchPromotions();
      await fetchPromotionById(id);
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat memperbarui promosi');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== DELETE =====================
  Future<void> deletePromotion(String id) async {
    try {
      final res = await PromotionService.deletePromotion(id);
      if (res.statusCode == 200) {
        promotionList.removeWhere((p) => p.id == id);
        _applyFilter();
        AppToast.show('Promosi berhasil dihapus');
        if (Get.currentRoute != '/promotions') Get.back();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus promosi');
    }
  }

  void confirmDelete(String id, String name) async {
    final confirm = await AppDialog.confirm(
      title: 'Hapus Promosi',
      content: 'Yakin ingin menghapus promosi "$name"?',
    );
    if (confirm) deletePromotion(id);
  }

  // ===================== TOGGLE ACTIVE =====================
  Future<void> toggleActive(PromotionData promo) async {
    final idx = promotionList.indexWhere((p) => p.id == promo.id);
    if (idx == -1) return;

    // optimistic update — langsung update UI
    promotionList[idx] = promo.copyWith(isActive: !promo.isActive);
    _applyFilter();

    try {
      final res = await PromotionService.updatePromotion(promo.id, {
        'name': promo.name,
        'code': promo.code,
        'type': promo.type,
        'description': promo.description ?? '',
        'valid_from': _formatDateFrom(promo.validFrom),
        'valid_to': _formatDateTo(promo.validTo),
        'usage_limit': promo.usageLimit,
        'is_active': !promo.isActive,
        'stackable': promo.stackable,
      });

      if (res.statusCode == 200) {
        AppToast.show(
          promo.isActive ? 'Promosi dinonaktifkan' : 'Promosi diaktifkan',
        );
      } else {
        // rollback kalau gagal
        promotionList[idx] = promo;
        _applyFilter();
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      // rollback
      promotionList[idx] = promo;
      _applyFilter();
      AppToast.show('Gagal mengubah status promosi');
    }
  }

  // ===================== CONDITIONS =====================
  Future<bool> addCondition(String promotionId) async {
    if (conditionType.value.isEmpty) {
      AppToast.show('Tipe syarat harus dipilih');
      return false;
    }
    if (conditionOperator.value.isEmpty) {
      AppToast.show('Operator harus dipilih');
      return false;
    }
    if (conditionValueC.text.trim().isEmpty) {
      AppToast.show('Value harus diisi');
      return false;
    }
    if (conditionNeedsTargetId(conditionType.value) &&
        conditionTargetIdC.text.trim().isEmpty) {
      AppToast.show('Target ID harus diisi');
      return false;
    }

    isSubmitting.value = true;
    try {
      final payload = {
        'condition_type': conditionType.value,
        'operator': conditionOperator.value,
        'value': conditionValueC.text.trim(),
        'target_type': conditionNeedsTargetId(conditionType.value)
            ? conditionType.value
            : null,
        'target_id': conditionNeedsTargetId(conditionType.value)
            ? conditionTargetIdC.text.trim()
            : null,
      };
      final res = await PromotionService.addCondition(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.show('Syarat berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        resetConditionForm();
        return true;
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
      return false;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menambahkan syarat');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteCondition(String promotionId, String conditionId) async {
    try {
      final res = await PromotionService.deleteCondition(
        promotionId,
        conditionId,
      );
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        AppToast.show('Syarat berhasil dihapus');
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus syarat');
    }
  }

  // ===================== REWARDS =====================
  Future<bool> addReward(String promotionId) async {
    if (rewardType.value.isEmpty) {
      AppToast.show('Tipe reward harus dipilih');
      return false;
    }
    if (rewardType.value == 'free_item') {
      if (freeVariantIdC.text.trim().isEmpty) {
        AppToast.show('Variant ID harus diisi');
        return false;
      }
    } else {
      if (discountValueC.text.trim().isEmpty) {
        AppToast.show('Nilai diskon harus diisi');
        return false;
      }
      final parsedDiscountValue = double.tryParse(discountValueC.text.trim());
      if (parsedDiscountValue == null || parsedDiscountValue <= 0) {
        AppToast.show('Nilai diskon harus lebih besar dari 0');
        return false;
      }
      if (discountMode.value.isEmpty) {
        AppToast.show('Mode diskon harus dipilih');
        return false;
      }
    }

    isSubmitting.value = true;
    try {
      final Map<String, dynamic> payload;
      if (rewardType.value == 'free_item') {
        payload = {
          'reward_type': rewardType.value,
          'free_variant_id': freeVariantIdC.text.trim(),
          'free_qty': int.tryParse(freeQtyC.text) ?? 1,
        };
      } else {
        payload = {
          'reward_type': rewardType.value,
          'discount_value': double.tryParse(discountValueC.text) ?? 0,
          'discount_mode': discountMode.value,
          'max_discount_amount': double.tryParse(maxDiscountC.text) ?? 0,
        };
      }

      final res = await PromotionService.addReward(promotionId, payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        AppToast.show('Reward berhasil ditambahkan');
        await fetchPromotionById(promotionId);
        resetRewardForm();
        return true;
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show(_parseError(res.body));
      }
      return false;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menambahkan reward');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> deleteReward(String promotionId, String rewardId) async {
    try {
      final res = await PromotionService.deleteReward(promotionId, rewardId);
      if (res.statusCode == 200) {
        await fetchPromotionById(promotionId);
        AppToast.show('Reward berhasil dihapus');
      } else {
        AppToast.show(_parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus reward');
    }
  }

  // ===================== DETAIL PAGE HELPERS =====================
  List<PromotionCondition> get detailConditions =>
      selectedPromotion.value?.conditions ?? [];

  List<PromotionReward> get detailRewards =>
      selectedPromotion.value?.rewards ?? [];

  String get detailValidPeriod {
    final p = selectedPromotion.value;
    if (p == null) return '';
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    return '${df.format(p.validFrom)} – ${df.format(p.validTo)}';
  }

  String get detailUsageDisplay {
    final p = selectedPromotion.value;
    if (p == null) return '';
    return p.usageLimit == 0 ? 'Unlimited' : '${p.usageCount}/${p.usageLimit}x';
  }

  String get detailStackableLabel =>
      (selectedPromotion.value?.stackable ?? false) ? 'Ya' : 'Tidak';

  String get detailStatusLabel =>
      (selectedPromotion.value?.isActive ?? false) ? 'Aktif' : 'Tidak Aktif';

  String rewardSubtitle(PromotionReward r) {
    if (r.rewardType == 'free_item') {
      var text = 'Qty: ${r.freeQty}';
      if ((r.freeVariantId ?? '').isNotEmpty) {
        final shortId = r.freeVariantId!.length > 8
            ? '${r.freeVariantId!.substring(0, 8)}...'
            : r.freeVariantId!;
        text += ' • Variant: $shortId';
      }
      return text;
    }
    var text = '${r.discountValue} • ${r.discountModeLabel}';
    final maxDisc = r.maxDiscountAmount ?? 0;
    if (maxDisc > 0) text += ' • maks Rp${maxDisc.toStringAsFixed(0)}';
    return text;
  }

  void setDate(DateTime date, {required bool isFrom}) {
    if (isFrom) {
      validFrom.value = date;
    } else {
      validTo.value = date;
    }
  }

  // ===================== PRIVATE =====================

  String _formatDateFrom(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} 00:00:00';

  String _formatDateTo(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} 23:59:59';

  Map<String, dynamic> _buildPayload() => {
    'name': nameC.text.trim(),
    'code': codeC.text.trim().toUpperCase(),
    'type': selectedType.value,
    'description': descC.text.trim(),
    'valid_from': _formatDateFrom(validFrom.value!),
    'valid_to': _formatDateTo(validTo.value!),
    'usage_limit': int.tryParse(usageLimitC.text) ?? 0,
    'is_active': isActive.value,
    'stackable': stackable.value,
  };

  String _parseError(String body) {
    try {
      return jsonDecode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }

  // ===================== DIRTY TRACKING =====================
  final isDirty = false.obs;

  String _snapName = '';
  String _snapCode = '';
  String _snapDesc = '';
  String _snapUsageLimit = '';
  String _snapType = '';
  DateTime? _snapValidFrom;
  DateTime? _snapValidTo;
  bool _snapIsActive = true;
  bool _snapStackable = false;

  Worker? _typeWorker;
  Worker? _validFromWorker;
  Worker? _validToWorker;
  Worker? _isActiveWorker;
  Worker? _stackableWorker;

  void _takeSnapshot() {
    _snapName = nameC.text;
    _snapCode = codeC.text;
    _snapDesc = descC.text;
    _snapUsageLimit = usageLimitC.text;
    _snapType = selectedType.value;
    _snapValidFrom = validFrom.value;
    _snapValidTo = validTo.value;
    _snapIsActive = isActive.value;
    _snapStackable = stackable.value;
  }

  void checkDirty() {
    isDirty.value =
        nameC.text != _snapName ||
        codeC.text != _snapCode ||
        descC.text != _snapDesc ||
        usageLimitC.text != _snapUsageLimit ||
        selectedType.value != _snapType ||
        validFrom.value != _snapValidFrom ||
        validTo.value != _snapValidTo ||
        isActive.value != _snapIsActive ||
        stackable.value != _snapStackable;
  }

  void _listenFormChanges() {
    for (final c in [nameC, codeC, descC, usageLimitC]) {
      c.removeListener(checkDirty);
      c.addListener(checkDirty);
    }

    _typeWorker?.dispose();
    _validFromWorker?.dispose();
    _validToWorker?.dispose();
    _isActiveWorker?.dispose();
    _stackableWorker?.dispose();

    _typeWorker = ever(selectedType, (_) => checkDirty());
    _validFromWorker = ever(validFrom, (_) => checkDirty());
    _validToWorker = ever(validTo, (_) => checkDirty());
    _isActiveWorker = ever(isActive, (_) => checkDirty());
    _stackableWorker = ever(stackable, (_) => checkDirty());
  }

  // ===================== REWARD FORM DIRTY =====================
  bool get isRewardDirty {
    if (rewardType.value.isEmpty) return false;
    if (rewardType.value == 'free_item') {
      return freeVariantIdC.text.trim().isNotEmpty;
    }
    return discountValueC.text.trim().isNotEmpty ||
        discountMode.value.isNotEmpty;
  }

  // ===================== CONDITION FORM DIRTY =====================
  bool get isConditionDirty =>
      conditionType.value.isNotEmpty ||
      conditionOperator.value.isNotEmpty ||
      conditionValueC.text.trim().isNotEmpty;

  Future<void> resolveConditionNames() async {
    final productC = Get.find<ProductController>();
    final categoryC = Get.find<CategoryController>();
    final variantC = Get.find<ProductVariantController>();

    await Future.wait([
      if (productC.productList.isEmpty) productC.fetchProducts(),
      if (categoryC.categoryList.isEmpty) categoryC.fetchCategories(),
      if (variantC.allVariants.isEmpty) variantC.fetchAllVariants(),
    ]);
  }
}