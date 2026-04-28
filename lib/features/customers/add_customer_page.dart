import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class AddCustomerPage extends StatelessWidget {
  AddCustomerPage({super.key});

  final controller = Get.find<CustomerController>();

  @override
  Widget build(BuildContext context) {
    final String? customerId = Get.arguments as String?;
    final bool isEdit = customerId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.resetForm();
      if (isEdit) {
        await controller.fetchCustomerById(customerId);
        final c = controller.selectedCustomer.value;
        if (c != null) controller.populateForm(c);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!controller.isDirty.value) {
          controller.resetForm();
          Get.back();
          return;
        }
        final shouldPop = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Perubahan belum disimpan'),
            content: const Text('Yakin mau keluar? Perubahan akan hilang.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Tetap di sini'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          controller.resetForm();
          Get.back();
        }
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Obx(() {
          if (controller.isLoading.value &&
              isEdit &&
              controller.selectedCustomer.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _inputField(
                  ctrl: controller.nameC,
                  label: 'Nama',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _inputField(
                  ctrl: controller.phoneC,
                  label: 'Telepon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _inputField(
                  ctrl: controller.emailC,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withAlpha(60)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonFormField<String>(
                      value: controller.selectedMemberType.value,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Member',
                        border: InputBorder.none,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'regular',
                          child: Text('Regular'),
                        ),
                        DropdownMenuItem(
                          value: 'member',
                          child: Text('Member'),
                        ),
                        DropdownMenuItem(value: 'vip', child: Text('VIP')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedMemberType.value = val;
                          controller.markDirty();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          controller.isLoading.value ||
                              !controller.isDirty.value
                          ? null
                          : () async {
                              if (controller.nameC.text.trim().isEmpty) {
                                Get.snackbar('Validasi', 'Nama harus diisi');
                                return;
                              }
                              bool success;
                              if (isEdit) {
                                success = await controller.updateCustomer(
                                  id: customerId,
                                  name: controller.nameC.text.trim(),
                                  phone: controller.phoneC.text.trim(),
                                  email: controller.emailC.text.trim(),
                                  memberType:
                                      controller.selectedMemberType.value,
                                );
                              } else {
                                success = await controller.createCustomer(
                                  name: controller.nameC.text.trim(),
                                  phone: controller.phoneC.text.trim(),
                                  email: controller.emailC.text.trim(),
                                  memberType:
                                      controller.selectedMemberType.value,
                                );
                              }
                              if (success) {
                                controller.resetForm();
                                Get.until(
                                  (route) =>
                                      route.settings.name == AppRoutes.customer,
                                );
                              }
                            },
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'Simpan Perubahan' : 'Simpan',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withAlpha(60)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: (_) =>
            Get.find<CustomerController>().markDirty(), // ← isDirty
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
