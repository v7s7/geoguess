import 'package:flutter/material.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../models/country.dart';
import '../widgets/flag_box.dart';

class LearnPage extends StatefulWidget {
  final List<Country> countries;

  const LearnPage({super.key, required this.countries});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String _selectedRegion = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // 1. Filter Logic
    final filteredCountries = widget.countries.where((c) {
      final matchesRegion = _selectedRegion == 'All' || c.region == _selectedRegion;
      final matchesSearch = c.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            c.nameAr.contains(_searchQuery);
      return matchesRegion && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.learn),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 2. Continent Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(l10n.all, 'All'),
                _buildFilterChip(l10n.africa, 'Africa'),
                _buildFilterChip(l10n.americas, 'Americas'),
                _buildFilterChip(l10n.asia, 'Asia'),
                _buildFilterChip(l10n.europe, 'Europe'),
                _buildFilterChip(l10n.oceania, 'Oceania'),
              ],
            ),
          ),
          
          // 3. Grid of Flags
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 items per row
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, 
              ),
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                return _buildLearnCard(context, country, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRegion == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() {
            _selectedRegion = value;
          });
        },
        selectedColor: Colors.indigo.shade100,
        checkmarkColor: Colors.indigo,
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context, Country country, AppLocalizations l10n) {
    return InkWell(
      onTap: () => _showDetailsDialog(context, country, l10n),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: FlagBox(url: country.flagUrl, height: double.infinity),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      country.localizedName(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tapToReveal,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Country country, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 24),
              // Flag
              FlagBox(url: country.flagUrl, height: 150),
              const SizedBox(height: 24),
              
              // Name
              Text(
                country.localizedName(context),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                country.nameEn, // Always show English name as subtitle for learners
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              
              // Connection Hints
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHintItem(Icons.public, l10n.region, country.region),
                  _buildHintItem(Icons.location_city, l10n.capital, country.capital),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintItem(IconData icon, String label, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.indigo.shade50,
          child: Icon(icon, color: Colors.indigo),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}