class AdPreferences {
  const AdPreferences({
    this.showParkingAds = true,
    this.showInsuranceAds = false,
    this.showMaintenanceAds = false,
    this.showLocalDeals = true,
  });

  final bool showParkingAds;
  final bool showInsuranceAds;
  final bool showMaintenanceAds;
  final bool showLocalDeals;

  AdPreferences copyWith({
    bool? showParkingAds,
    bool? showInsuranceAds,
    bool? showMaintenanceAds,
    bool? showLocalDeals,
  }) {
    return AdPreferences(
      showParkingAds: showParkingAds ?? this.showParkingAds,
      showInsuranceAds: showInsuranceAds ?? this.showInsuranceAds,
      showMaintenanceAds: showMaintenanceAds ?? this.showMaintenanceAds,
      showLocalDeals: showLocalDeals ?? this.showLocalDeals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showParkingAds': showParkingAds,
      'showInsuranceAds': showInsuranceAds,
      'showMaintenanceAds': showMaintenanceAds,
      'showLocalDeals': showLocalDeals,
    };
  }

  factory AdPreferences.fromJson(Map<String, dynamic> json) {
    return AdPreferences(
      showParkingAds: json['showParkingAds'] as bool? ?? true,
      showInsuranceAds: json['showInsuranceAds'] as bool? ?? false,
      showMaintenanceAds: json['showMaintenanceAds'] as bool? ?? false,
      showLocalDeals: json['showLocalDeals'] as bool? ?? true,
    );
  }
}
