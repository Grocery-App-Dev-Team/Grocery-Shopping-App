import 'package:flutter/material.dart';
import '../../../../core/location/province_api.dart';
import '../../../../core/utils/app_localizations.dart';

class AddressSelection2Dropdowns extends StatefulWidget {
  final String? initialValue;
  final Function(String) onAddressChanged;

  const AddressSelection2Dropdowns({
    super.key,
    this.initialValue,
    required this.onAddressChanged,
  });

  @override
  State<AddressSelection2Dropdowns> createState() => _AddressSelection2DropdownsState();
}

class _AddressSelection2DropdownsState extends State<AddressSelection2Dropdowns> {
  final ProvinceApi _provinceApi = ProvinceApi();
  
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
    _parseInitialValue();
    _loadProvinces();
  }

  void _parseInitialValue() {
    if (widget.initialValue == null || widget.initialValue!.isEmpty) return;
    
    final parts = widget.initialValue!.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 3) {
      // Expecting: [Street], [Ward], [Province]
      _streetController.text = parts[0];
      // We can't easily select items in dropdowns until they are loaded
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final list = await _provinceApi.getProvincesV2();
      setState(() {
        _provinces = list;
        _isLoadingProvinces = false;
        
        // Try to match initial province
        if (widget.initialValue != null) {
          final parts = widget.initialValue!.split(',').map((e) => e.trim()).toList();
          if (parts.isNotEmpty) {
            final provName = parts.last.toLowerCase();
            try {
              _selectedProvince = _provinces.firstWhere(
                (p) {
                  final name = p.name.toLowerCase();
                  return name == provName || name.contains(provName) || provName.contains(name);
                }
              );
            } catch (_) {
              _selectedProvince = _provinces.isNotEmpty ? _provinces.first : null;
            }
            
            if (_selectedProvince != null) _loadWards(_selectedProvince!.code);
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Future<void> _loadWards(int provinceCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _selectedWard = null;
    });
    try {
      final list = await _provinceApi.getWardsByProvince(provinceCode);
      setState(() {
        _wards = list;
        _isLoadingWards = false;
        
        // Try to match initial ward
        if (widget.initialValue != null) {
          final parts = widget.initialValue!.split(',').map((e) => e.trim()).toList();
          if (parts.length >= 2) {
            final wardName = parts[parts.length - 2];
            try {
              _selectedWard = _wards.firstWhere(
                (w) => w.name.toLowerCase() == wardName.toLowerCase()
              );
            } catch (_) {}
          }
        }
      });
    } catch (e) {
      setState(() => _isLoadingWards = false);
    }
  }

  void _notifyChanges() {
    final province = _selectedProvince?.name ?? '';
    final ward = _selectedWard?.name ?? '';
    final street = _streetController.text.trim();
    
    if (province.isNotEmpty && ward.isNotEmpty && street.isNotEmpty) {
      widget.onAddressChanged('$street, $ward, $province');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown 1: Province
        DropdownButtonFormField<LocationItem>(
          value: _selectedProvince,
          decoration: _decoration(l.translate('province')),
          items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (val) {
            setState(() => _selectedProvince = val);
            if (val != null) _loadWards(val.code);
            _notifyChanges();
          },
          validator: (v) => v == null ? l.translate('select_province') : null,
          hint: _isLoadingProvinces ? Text(l.byLocale(vi: 'Đang tải...', en: 'Loading...')) : Text(l.translate('select_province')),
          dropdownColor: Theme.of(context).cardColor,
          elevation: 8,
          icon: const Icon(Icons.map_outlined, size: 18),
        ),
        const SizedBox(height: 16),
        
        // Dropdown 2: Ward
        DropdownButtonFormField<LocationItem>(
          value: _selectedWard,
          decoration: _decoration(l.translate('ward')),
          items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w.name, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: _selectedProvince == null ? null : (val) {
            setState(() => _selectedWard = val);
            _notifyChanges();
          },
          validator: (v) => v == null ? l.translate('select_ward') : null,
          hint: _isLoadingWards ? Text(l.byLocale(vi: 'Đang tải...', en: 'Loading...')) : Text(l.translate('select_ward')),
          disabledHint: Text(l.byLocale(vi: 'Chọn Tỉnh/Thành trước', en: 'Select Province first')),
          dropdownColor: Theme.of(context).cardColor,
          elevation: 8,
          icon: const Icon(Icons.location_city_outlined, size: 18),
        ),
        const SizedBox(height: 16),
        
        // Input: Street
        TextFormField(
          controller: _streetController,
          decoration: _decoration(l.translate('street')).copyWith(
            prefixIcon: const Icon(Icons.home_outlined, size: 18),
          ),
          onChanged: (_) => _notifyChanges(),
          validator: (v) => v!.isEmpty ? l.translate('address_required') : null,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
      fillColor: Theme.of(context).cardColor,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
