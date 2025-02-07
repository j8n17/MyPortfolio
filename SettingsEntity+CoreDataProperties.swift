import Foundation
import CoreData

extension SettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingsEntity> {
        return NSFetchRequest<SettingsEntity>(entityName: "SettingsEntity")
    }
    
    @NSManaged public var cash: Double
    @NSManaged public var threshold: Double
}

extension SettingsEntity {
    /// SettingsEntity가 존재하지 않으면 새로 생성하여 반환
    static func fetchOrCreate(context: NSManagedObjectContext) -> SettingsEntity {
        let request: NSFetchRequest<SettingsEntity> = SettingsEntity.fetchRequest()
        if let settings = (try? context.fetch(request))?.first {
            return settings
        } else {
            let newSettings = SettingsEntity(context: context)
            newSettings.cash = 0.0
            newSettings.threshold = 12.0
            return newSettings
        }
    }
}
