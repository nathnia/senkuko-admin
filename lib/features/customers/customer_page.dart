import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_filter_chips.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/customers/customer_card.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage>
    with WidgetsBindingObserver {
  final controller = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FIX: sebelumnya StatelessWidget — gak ada initState(), padahal
    // CustomerController udah punya refreshIfStale() yang komentarnya
    // sendiri bilang "Panggil dari CustomerPage.initState()" — cuma emang
    // gak pernah beneran dipanggil dari sini. fetchCustomers() gak pakai
    // CacheService (murni network call), jadi aman dipanggil langsung
    // tanpa addPostFrameCallback (beda sama Banner/Category yang punya
    // jalur cache-hit sinkron).
    //
    // resetFilters() juga dipanggil di sini — controller permanent bikin
    // searchText/statusFilter/groupFilter bertahan antar kunjungan,
    // sementara AppSearchBar-nya sendiri statenya baru tiap halaman ini
    // dibuka (keliatan kosong). Tanpa reset, search text lama tetap
    // dipakai buat filter walau kotaknya keliatan kosong.
    controller.resetFilters();
    controller.refreshIfStale();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nutup celah: user minimize app lama (mis. ada transaksi baru yang
    // ngubah total_spend pelanggan), balik lagi — data mungkin udah basi.
    if (state == AppLifecycleState.resumed) {
      controller.refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(onTap: () => Get.back()),
        title: const Text(
          'Pelanggan',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: AppSearchBar(
              hintText: 'Cari nama, atau telepon,...',
              onChanged: controller.updateSearch,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.resetForAdd(); // optional, initState sudah handle
          Get.toNamed(AppRoutes.customerForm);
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => AppFilterChips(
                    items: const [
                      FilterChipItem(label: 'Semua'),
                      FilterChipItem(label: 'Aktif'),
                      FilterChipItem(label: 'Nonaktif'),
                      FilterChipItem(label: 'Eceran'),
                      FilterChipItem(label: 'Grosir'),
                    ],
                    selectedLabel: controller.combinedFilterLabel,
                    onChipTap: controller.setCombinedFilter,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.customerList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.hasError.value) {
                return AppErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.fetchCustomers,
                );
              }
              final list = controller.filteredCustomers;
              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada pelanggan ditemukan',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.fetchCustomers,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final customer = list[index];
                    return CustomerCard(
                      customer: customer,
                      onTap: () => Get.toNamed(
                        // ← tambah
                        AppRoutes.customerForm,
                        arguments: customer,
                      ),
                      onToggleStatus: () =>
                          controller.toggleCustomerStatus(customer),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}