import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../model/inspection_model.dart';
import '../../services/inspection_service.dart';
import '../../widgets/inspection_list_tile.dart';
import '../../widgets/parakh_app_bar.dart';

class ScannedProductsScreen extends StatefulWidget {
  final ComplianceStatus? initialFilter;
  const ScannedProductsScreen({super.key, this.initialFilter});

  @override
  State<ScannedProductsScreen> createState() => _ScannedProductsScreenState();
}

class _ScannedProductsScreenState extends State<ScannedProductsScreen> {
  late ComplianceStatus? _selectedFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InspectionModel> get _filteredInspections {
    final all = InspectionService().cachedInspections;
    return all.where((item) {
      if (_selectedFilter != null && item.complianceStatus != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (item.productName ?? '').toLowerCase();
        final brand = (item.brand ?? '').toLowerCase();
        final id = item.id.toString();
        return name.contains(q) || brand.contains(q) || id.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredInspections;

    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: const ParakhAppBar(
        title: 'Inspected Packages',
        subtitle: 'All field inspection records',
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: ParakhColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by product name, brand, or ID...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'All (${InspectionService().cachedInspections.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(ComplianceStatus.compliant, 'Compliant'),
                      const SizedBox(width: 8),
                      _buildFilterChip(ComplianceStatus.nonCompliant, 'Non-Compliant'),
                      const SizedBox(width: 8),
                      _buildFilterChip(ComplianceStatus.needsReview, 'Needs Review'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List or Empty
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: ParakhColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Inspection Records Found',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ParakhColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try adjusting your search query or filter criteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ParakhColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return InspectionListTile(
                        inspection: item,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.inspectionResult,
                            arguments: item.id,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ComplianceStatus? status, String label) {
    final isSelected = _selectedFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      selectedColor: ParakhColors.accent,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : ParakhColors.textPrimary,
      ),
      backgroundColor: ParakhColors.backgroundDarker,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? ParakhColors.accent : ParakhColors.border,
        ),
      ),
    );
  }
}
