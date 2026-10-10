import Foundation

enum CacheCleaner {
    /// Removes only cache files belonging to AIMX IOS inside its iOS sandbox.
    static func clearAppCaches() -> Int {
        let fileManager = FileManager.default
        guard
            let cacheURL = try? fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ),
            let contents = try? fileManager.contentsOfDirectory(
                at: cacheURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else {
            return 0
        }

        var removedItems = 0
        for itemURL in contents {
            do {
                try fileManager.removeItem(at: itemURL)
                removedItems += 1
            } catch {
                // Keep going so one undeletable cache item does not block the rest.
            }
        }
        return removedItems
    }
}
