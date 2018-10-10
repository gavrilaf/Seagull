import Foundation

func getResourcesPath(filePath: String, bundleClass: AnyClass) -> String {
    let path = FileManager.default.currentDirectoryPath + "/" + filePath
    #if os(Linux)
    return path
    #else
    if FileManager.default.fileExists(atPath: path) {
        return path
    }
    
    let bundlePath = Bundle(for: bundleClass).resourcePath!
    return bundlePath[bundlePath.startIndex..<bundlePath.range(of: "Seagull/")!.upperBound] + "/" + filePath
    #endif
}
