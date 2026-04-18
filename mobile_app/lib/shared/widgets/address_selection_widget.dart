import 'package:flutter/material.dart';
import '../../core/location/province_api.dart';

class AddressSelectionWidget extends StatefulWidget {
  final String? initialAddress;
  final Function(String fullAddress, String province, String ward, String street) onAddressChanged;

  const AddressSelectionWidget({
    super.key,
    this.initialAddress,
    required this.onAddressChanged,
  });

  @override
  State<AddressSelectionWidget> createState() => _AddressSelectionWidgetState();
}

class _AddressSelectionWidgetState extends State<AddressSelectionWidget> {
  final ProvinceApi _api = ProvinceApi();
  
  List<LocationItem> _provinces = [];
  List<LocationItem> _wards = [];
  
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;
  final TextEditingController _streetController = TextEditingController();
  
  bool _isLoadingProvinces = false;
  bool _isLoadingWards = false;

  @override
  void initState() {
    super.initState();
    _parseInitialAddress();
    _loadProvinces();
  }

  void _parseInitialAddress() {
    if (widget.initialAddress == null || widget.initialAddress!.isEmpty) return;
    
    // Simple parsing assumption: "Street, Ward, Province"
    final parts = widget.initialAddress!.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      _streetController.text = parts[0];
      // We can't easily match ID/Codes from just strings without the full list, 
      // but we store the string parts to help UI if needed.
    } else {
      _streetController.text = widget.initialAddress!;
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final provinces = await _api.getProvincesV2();
      if (mounted) {
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _loadWards(int provinceCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      // Trying to get wards directly from province as per user request and ProvinceApi implementation
      final wards = await _api.getWardsByProvince(provinceCode);
      if (mounted) {
        setState(() {
          _wards = wards;
          _isLoadingWards = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWards = false);
    }
  }

  void _notifyChanged() {
    final provinceName = _selectedProvince?.name ?? '';
    final wardName = _selectedWard?.name ?? '';
    final streetName = _streetController.text.trim();
    
    String fullAddress = '';
    if (streetName.isNotEmpty) fullAddress += streetName;
    if (wardName.isNotEmpty) fullAddress += (fullAddress.isEmpty ? '' : ', ') + wardName;
    if (provinceName.isNotEmpty) fullAddress += (fullAddress.isEmpty ? '' : ', ') + provinceName;
    
    widget.onAddressChanged(fullAddress, provinceName, wardName, streetName);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Province Dropdown
        DropdownButtonFormField<LocationItem>(
          value: _selectedProvince,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: 'Tỉnh / Thành phố',
            prefixIcon: const Icon(Icons.map_outlined, color: Colors.indigo),
            suffixIcon: _isLoadingProvinces ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
          ),
          items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (val) {
            setState(() => _selectedProvince = val);
            if (val != null) _loadWards(val.code);
            _notifyChanged();
          },
        ),
        const SizedBox(height: 16),
        
        // Ward Dropdown
        DropdownButtonFormField<LocationItem>(
          value: _selectedWard,
          dropdownColor: Theme.of(context).cardColor,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: 'Phường / Xã',
            prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.indigo),
            suffixIcon: _isLoadingWards ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
            enabled: _selectedProvince != null,
          ),
          items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (val) {
            setState(() => _selectedWard = val);
            _notifyChanged();
          },
        ),
        const SizedBox(height: 16),
        
        // Street Input
        TextField(
          controller: _streetController,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: 'Số nhà, tên đường',
            prefixIcon: const Icon(Icons.home_outlined, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
          ),
          onChanged: (val) => _notifyChanged(),
        ),
      ],
    );
  }
}
