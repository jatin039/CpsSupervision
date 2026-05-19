import Foundation

enum Constants {
    static let cloudKitContainerID = "iCloud.com.cpssupervision.app"
    static let appGroupID = "group.com.cpssupervision.app"

    enum LogStatus: String, CaseIterable {
        case draft = "draft"
        case submitted = "submitted"
        case reviewed = "reviewed"

        var displayName: String {
            switch self {
            case .draft: return "Draft"
            case .submitted: return "Submitted"
            case .reviewed: return "Reviewed"
            }
        }
    }

    enum LocationType: String, CaseIterable {
        case home = "Home"
        case park = "Park"
        case school = "School"
        case facility = "Facility"
        case communityCenter = "Community Center"
        case other = "Other"
    }

    enum SupervisorRelationship: String, CaseIterable {
        case fosterParent = "Foster Parent"
        case relative = "Relative"
        case caseWorker = "Case Worker"
        case professional = "Professional"
        case volunteer = "Volunteer"
        case other = "Other"
    }

    enum IncidentType: String, CaseIterable {
        case behaviorConcern = "Behavior Concern"
        case medical = "Medical"
        case safety = "Safety"
        case propertyDamage = "Property Damage"
        case other = "Other"
    }

    enum IncidentSeverity: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }

    enum UserDefaultsKey {
        static let biometricEnabled = "biometricEnabled"
        static let currentUserName = "currentUserName"
        static let exportIncludePhotos = "exportIncludePhotos"
    }
}
