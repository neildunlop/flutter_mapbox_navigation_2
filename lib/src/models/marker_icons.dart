/// Predefined icon identifiers for static markers
/// These icons are embedded in the native platforms and can be referenced by ID
class MarkerIcons {
  // Transportation
  static const String petrolStation = 'petrol_station';
  static const String chargingStation = 'charging_station';
  static const String parking = 'parking';
  static const String busStop = 'bus_stop';
  static const String trainStation = 'train_station';
  static const String airport = 'airport';
  static const String port = 'port';
  
  // Food & Services
  static const String restaurant = 'restaurant';
  static const String cafe = 'cafe';
  static const String hotel = 'hotel';
  static const String shop = 'shop';
  static const String pharmacy = 'pharmacy';
  static const String hospital = 'hospital';
  static const String police = 'police';
  static const String fireStation = 'fire_station';
  
  // Scenic & Recreation
  static const String scenic = 'scenic';
  static const String park = 'park';
  static const String beach = 'beach';
  static const String mountain = 'mountain';
  static const String lake = 'lake';
  static const String waterfall = 'waterfall';
  static const String viewpoint = 'viewpoint';
  static const String hiking = 'hiking';
  
  // Safety & Traffic
  static const String speedCamera = 'speed_camera';
  static const String accident = 'accident';
  static const String construction = 'construction';
  static const String trafficLight = 'traffic_light';
  static const String speedBump = 'speed_bump';
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