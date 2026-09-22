import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/parakh_app_bar.dart';

class RuleItem {
  final String ruleNumber;
  final String title;
  final String requirement;
  final String penaltyOrNotes;

  const RuleItem({
    required this.ruleNumber,
    required this.title,
    required this.requirement,
    required this.penaltyOrNotes,
  });
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<RuleItem> _rules = const [
    RuleItem(
      ruleNumber: 'Rule 6(1)(a)',
      title: 'Name & Address of Manufacturer / Packer / Importer',
      requirement:
          'Every package shall bear the name and complete address of the manufacturer, or where the manufacturer is not the packer, the name and complete address of the manufacturer and the packer.',
      penaltyOrNotes: 'Mandatory on Principal Display Panel or prominent face.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(b)',
      title: 'Generic or Common Name of Commodity',
      requirement:
          'The common or generic names of the commodity contained in the package and where such commodity is packaged in more than one piece, the number and dimensions of each piece.',
      penaltyOrNotes: 'Prevents misleading or obscure brand naming without commodity clarity.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(c)',
      title: 'Net Quantity in Standard Metric Units',
      requirement:
          'The net quantity, in terms of standard unit of weight or measure, of the commodity contained in the package. Standard symbols: g, kg, ml, l, m, cm.',
      penaltyOrNotes: 'Non-standard abbreviations (e.g. gms, kgs, ltr) are strictly non-compliant.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(d)',
      title: 'Month & Year of Manufacture / Pre-packing',
      requirement:
          'The month and year in which the commodity is manufactured or pre-packed or imported shall be declared conspicuously.',
      penaltyOrNotes: 'Format accepted: MM/YYYY or Month Year.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(da)',
      title: 'Best Before / Use By / Expiry Date',
      requirement:
          'For commodities which may become unfit for human consumption after a period of time, the "Best Before" or "Use By" date, month and year shall be declared.',
      penaltyOrNotes: 'Mandatory on food, cosmetics, and perishable packaged items.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(e)',
      title: 'Maximum Retail Price (MRP Inclusive of All Taxes)',
      requirement:
          'Retail sale price of the package shall be clearly declared as "Maximum or Max. Retail Price ₹ / Rs. ..... (inclusive of all taxes)". Dual MRP on identical commodities is prohibited.',
      penaltyOrNotes: 'Violation under Section 36 of Legal Metrology Act carries compounding penalty.',
    ),
    RuleItem(
      ruleNumber: 'Rule 6(1)(f)',
      title: 'Consumer Care Redressal Details',
      requirement:
          'Name, address, telephone number, and official email address of the person or office who may be contacted in case of consumer complaints.',
      penaltyOrNotes: 'Must provide operational telephone number and valid email.',
    ),
    RuleItem(
      ruleNumber: 'Rule 9 & Sched. II',
      title: 'Minimum Font / Numeral Height Specifications',
      requirement:
          'Numeral heights on declarations depend on Principal Display Panel (PDP) area:\n• Up to 50 cm²: Minimum 1.0 mm height\n• 50 cm² to 100 cm²: Minimum 1.5 mm height\n• 100 cm² to 500 cm²: Minimum 2.5 mm height\n• 500 cm² to 2500 cm²: Minimum 4.0 mm height\n• Above 2500 cm²: Minimum 6.0 mm height',
      penaltyOrNotes: 'Applies to net quantity and MRP font sizing.',
    ),
  ];

  List<RuleItem> get _filteredRules {
    if (_searchQuery.isEmpty) return _rules;
    final q = _searchQuery.toLowerCase();
    return _rules.where((r) {
      return r.ruleNumber.toLowerCase().contains(q) ||
          r.title.toLowerCase().contains(q) ||
          r.requirement.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredRules;

    return Scaffold(
      backgroundColor: ParakhColors.backgroundDarker,
      appBar: const ParakhAppBar(
        title: 'Rules Assistant',
        subtitle: 'Legal Metrology (Packaged Commodities) Rules, 2011',
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: ParakhColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search rules (e.g. MRP, Net Quantity, Rule 6, Font Size)...',
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
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: ParakhColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ParakhColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.ruleNumber,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ParakhColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ParakhColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.requirement,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: ParakhColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ParakhColors.backgroundDarker,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  size: 16, color: ParakhColors.accentGold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.penaltyOrNotes,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: ParakhColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
