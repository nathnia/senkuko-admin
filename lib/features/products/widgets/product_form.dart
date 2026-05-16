import 'package:flutter/material.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/widgets/product_image_section.dart';
import 'package:senkukoadmin/features/products/widgets/product_info_form.dart';
import 'package:senkukoadmin/features/products/widgets/product_variant_form.dart';

class ProductFormWidgets {
  final ProductController controller;

  late final ProductImageSection _imageSection;
  late final ProductInfoForm _infoForm;
  late final ProductVariantForm _variantForm;

  ProductFormWidgets(this.controller) {
    _imageSection = ProductImageSection(controller);
    _infoForm = ProductInfoForm(controller);
    _variantForm = ProductVariantForm(controller);
  }

  // ── Delegasi ke masing-masing section ──

  Widget productImageGrid(String productId, {bool isAddMode = false}) =>
      _imageSection.productImageGrid(productId, isAddMode: isAddMode);

  Widget productForm() => _infoForm.productForm();

  Widget categorySelector() => _infoForm.categorySelector();

  void openCategoryPopup() => _infoForm.openCategoryPopup();

  Widget variantForm({bool isEditMode = false}) =>
      _variantForm.variantForm(isEditMode: isEditMode);

  Widget unitDropdown() => _variantForm.unitDropdown();

  void openUnitPopup() => _variantForm.openUnitPopup();

  Widget priceMatrix() => _variantForm.priceMatrix();
}