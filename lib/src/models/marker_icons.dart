/// Predefined icon identifiers for static markers
/// These icons are embedded in the native platforms and can be referenced by ID
class MarkerIcons {
  // Transportation
  /// Petrol station icon
  static const String petrolStation = 'petrol_station';
  /// Electric vehicle charging station icon
  static const String chargingStation = 'charging_station';
  /// Parking facility icon
  static const String parking = 'parking';
  /// Bus stop icon
  static const String busStop = 'bus_stop';
  /// Train station icon
  static const String trainStation = 'train_station';
  /// Airport icon
  static const String airport = 'airport';
  /// Port or harbor icon
  static const String port = 'port';
  
  // Food & Services
  /// Restaurant icon
  static const String restaurant = 'restaurant';
  /// Cafe icon
  static const String cafe = 'cafe';
  /// Hotel icon
  static const String hotel = 'hotel';
  /// Shop or store icon
  static const String shop = 'shop';
  /// Pharmacy icon
  static const String pharmacy = 'pharmacy';
  /// Hospital icon
  static const String hospital = 'hospital';
  /// Police station icon
  static const String police = 'police';
  /// Fire station icon
  static const String fireStation = 'fire_station';
  
  // Scenic & Recreation
  /// Scenic viewpoint icon
  static const String scenic = 'scenic';
  /// Park icon
  static const String park = 'park';
  /// Beach icon
  static const String beach = 'beach';
  /// Mountain icon
  static const String mountain = 'mountain';
  /// Lake icon
  static const String lake = 'lake';
  /// Waterfall icon
  static const String waterfall = 'waterfall';
  /// Viewpoint icon
  static const String viewpoint = 'viewpoint';
  /// Hiking trail icon
  static const String hiking = 'hiking';
  
  // Safety & Traffic
  /// Speed camera icon
  static const String speedCamera = 'speed_camera';
  /// Accident or hazard icon
  static const String accident = 'accident';
  /// Construction zone icon
  static const String construction = 'construction';
  /// Traffic light icon
  static const String trafficLight = 'traffic_light';
  /// Speed bump icon
  static const String speedBump = 'speed_bump';
  /// School zone icon
  static const String schoolZone = 'school_zone';
  
  // General
  static const String pin = 'pin';
  static const String star = 'star';
  static const String heart = 'heart';
  static const String flag = 'flag';
  static const String warning = 'warning';
  static const String info = 'info';
  static const String question = 'question';
  
  /// Returns all available icon IDs
  static List<String> getAllIcons() {
    return [
      // Transportation
      petrolStation,
      chargingStation,
      parking,
      busStop,
      trainStation,
      airport,
      port,
      
      // Food & Services
      restaurant,
      cafe,
      hotel,
      shop,
      pharmacy,
      hospital,
      police,
      fireStation,
      
      // Scenic & Recreation
      scenic,
      park,
      beach,
      mountain,
      lake,
      waterfall,
      viewpoint,
      hiking,
      
      // Safety & Traffic
      speedCamera,
      accident,
      construction,
      trafficLight,
      speedBump,
      schoolZone,
      
      // General
      pin,
      star,
      heart,
      flag,
      warning,
      info,
      question,
    ];
  }
  
  /// Returns icon IDs grouped by category
  static Map<String, List<String>> getIconsByCategory() {
    return {
      'Transportation': [
        petrolStation,
        chargingStation,
        parking,
        busStop,
        trainStation,
        airport,
        port,
      ],
      'Food & Services': [
        restaurant,
        cafe,
        hotel,
        shop,
        pharmacy,
        hospital,
        police,
        fireStation,
      ],
      'Scenic & Recreation': [
        scenic,
        park,
        beach,
        mountain,
        lake,
        waterfall,
        viewpoint,
        hiking,
      ],
      'Safety & Traffic': [
        speedCamera,
        accident,
        construction,
        trafficLight,
        speedBump,
        schoolZone,
      ],
      'General': [
        pin,
        star,
        heart,
        flag,
        warning,
        info,
        question,
      ],
    };
  }
  
  /// Validates if the given icon ID is supported
  static bool isValidIcon(String iconId) {
    return getAllIcons().contains(iconId);
  }
} 