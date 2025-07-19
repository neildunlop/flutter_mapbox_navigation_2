import Foundation
import UIKit

@objc public class IconResourceMapper: NSObject {
    
    @objc public static func getIconImage(for iconId: String) -> UIImage? {
        // Map icon IDs to system images or custom images
        switch iconId {
        // Basic icons
        case "ic_pin":
            return UIImage(systemName: "mappin")
        case "ic_star":
            return UIImage(systemName: "star")
        case "ic_heart":
            return UIImage(systemName: "heart")
        case "ic_flag":
            return UIImage(systemName: "flag")
        case "ic_warning":
            return UIImage(systemName: "exclamationmark.triangle")
        case "ic_info":
            return UIImage(systemName: "info.circle")
        case "ic_question":
            return UIImage(systemName: "questionmark.circle")
            
        // Transportation
        case "ic_petrol_station":
            return UIImage(systemName: "fuelpump")
        case "ic_charging_station":
            return UIImage(systemName: "bolt.circle")
        case "ic_parking":
            return UIImage(systemName: "car")
        case "ic_bus_stop":
            return UIImage(systemName: "bus")
        case "ic_train_station":
            return UIImage(systemName: "train.side.front.car")
        case "ic_airport":
            return UIImage(systemName: "airplane")
        case "ic_port":
            return UIImage(systemName: "ferry")
            
        // Food & Services
        case "ic_restaurant":
            return UIImage(systemName: "fork.knife")
        case "ic_cafe":
            return UIImage(systemName: "cup.and.saucer")
        case "ic_hotel":
            return UIImage(systemName: "bed.double")
        case "ic_shop":
            return UIImage(systemName: "cart")
        case "ic_pharmacy":
            return UIImage(systemName: "pills")
        case "ic_hospital":
            return UIImage(systemName: "cross")
        case "ic_police":
            return UIImage(systemName: "shield")
        case "ic_fire_station":
            return UIImage(systemName: "flame")
            
        // Scenic & Recreation
        case "ic_scenic":
            return UIImage(systemName: "mountain.2")
        case "ic_park":
            return UIImage(systemName: "leaf")
        case "ic_beach":
            return UIImage(systemName: "beach.umbrella")
        case "ic_mountain":
            return UIImage(systemName: "mountain.2")
        case "ic_lake":
            return UIImage(systemName: "drop")
        case "ic_waterfall":
            return UIImage(systemName: "drop.fill")
        case "ic_viewpoint":
            return UIImage(systemName: "binoculars")
        case "ic_hiking":
            return UIImage(systemName: "figure.hiking")
            
        // Safety & Traffic
        case "ic_speed_camera":
            return UIImage(systemName: "camera")
        case "ic_accident":
            return UIImage(systemName: "exclamationmark.triangle")
        case "ic_construction":
            return UIImage(systemName: "hammer")
        case "ic_traffic_light":
            return UIImage(systemName: "lightbulb")
        case "ic_speed_bump":
            return UIImage(systemName: "speedometer")
        case "ic_school_zone":
            return UIImage(systemName: "graduationcap")
            
        // Additional services
        case "ic_school":
            return UIImage(systemName: "graduationcap")
        case "ic_church":
            return UIImage(systemName: "building.columns")
        case "ic_shopping":
            return UIImage(systemName: "cart")
        case "ic_bank":
            return UIImage(systemName: "building.2")
        case "ic_atm":
            return UIImage(systemName: "creditcard")
        case "ic_gas_station":
            return UIImage(systemName: "fuelpump")
        case "ic_car_wash":
            return UIImage(systemName: "drop")
        case "ic_toll":
            return UIImage(systemName: "dollarsign.circle")
        case "ic_border":
            return UIImage(systemName: "flag")
        case "ic_custom":
            return UIImage(systemName: "mappin.circle")
        default:
            return UIImage(systemName: "mappin")
        }
    }
    
    @objc public static func getIconColor(for iconId: String) -> UIColor {
        // Map icon IDs to default colors
        switch iconId {
        case "ic_scenic":
            return UIColor.systemGreen
        case "ic_petrol_station", "ic_gas_station":
            return UIColor.systemOrange
        case "ic_restaurant":
            return UIColor.systemRed
        case "ic_hotel":
            return UIColor.systemBlue
        case "ic_hospital", "ic_pharmacy":
            return UIColor.systemRed
        case "ic_police", "ic_fire_station":
            return UIColor.systemRed
        case "ic_school":
            return UIColor.systemBlue
        case "ic_church":
            return UIColor.systemPurple
        case "ic_park":
            return UIColor.systemGreen
        case "ic_shopping":
            return UIColor.systemPink
        case "ic_bank", "ic_atm":
            return UIColor.systemGreen
        case "ic_car_wash":
            return UIColor.systemBlue
        case "ic_parking":
            return UIColor.systemGray
        case "ic_bus_stop", "ic_train_station", "ic_airport", "ic_port":
            return UIColor.systemBlue
        case "ic_accident":
            return UIColor.systemRed
        case "ic_construction":
            return UIColor.systemOrange
        case "ic_speed_camera":
            return UIColor.systemRed
        case "ic_toll":
            return UIColor.systemYellow
        case "ic_border":
            return UIColor.systemPurple
        default:
            return UIColor.systemRed
        }
    }
    
    @objc public static func getIconSize(for iconId: String) -> CGSize {
        // Return appropriate icon sizes
        switch iconId {
        case "ic_accident", "ic_construction", "ic_speed_camera":
            return CGSize(width: 32, height: 32) // Larger for important markers
        default:
            return CGSize(width: 24, height: 24) // Standard size
        }
    }
} 