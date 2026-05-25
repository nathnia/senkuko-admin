import 'package:flutter/material.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/widgets/product_image_section.dart';
import 'package:senkukoadmin/features/products/widgets/product_info_form.dart';

class ProductFormWidgets {
  final ProductController controller;

  late final ProductImageSection _imageSection;
  late final ProductInfoForm _infoForm;

  ProductFormWidgets(this.controller) {
    _imageSection = ProductImageSection(controller);
    _infoForm = ProductInfoForm(controller);
  }

  Widget productImageGrid(String productId, {bool isAddMode = false}) =>
      _imageSection.productImageGrid(productId, isAddMode: isAddMode);

  Widget productForm() => _infoForm.productForm();

  Widget categorySelector() => _infoForm.categorySelector();
}