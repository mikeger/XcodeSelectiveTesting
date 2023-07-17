//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import Foundation
import XCTest
import PathKit
import SelectiveTestShell
import Workspace
import TestConfigurator
@testable import SelectiveTestingCore

final class IntegrationTestTool {
    var projectPath: Path = ""

    func setUp() throws {
        let tmpPath = Path.temporary.absolute()
        guard let exampleInBundle = Bundle.module.path(forResource: "ExampleProject", ofType: "") else {
            fatalError("Missing ExampleProject in TestBundle")
        }
        projectPath = tmpPath + "ExampleProject"
        try? FileManager.default.removeItem(atPath: projectPath.string)
        try FileManager.default.copyItem(atPath: exampleInBundle, toPath: projectPath.string)
        FileManager.default.changeCurrentDirectoryPath(projectPath.string)
        try Shell.execOrFail("git init")
        try Shell.execOrFail("git config commit.gpgsign false")
        try Shell.execOrFail("git checkout -b main")
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Base\"")
        try Shell.execOrFail("git checkout -b feature")
    }
    
    func tearDown() throws {
        try? FileManager.default.removeItem(atPath: projectPath.string)
    }
    
    func changeFile(at path: Path) throws {
        let handle = FileHandle(forUpdatingAtPath: path.string)!
        try handle.seekToEnd()
        try handle.write(contentsOf: "\n \n".data(using: .utf8)!)
        try handle.close()
        
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }
    
    func addFile(at path: Path) throws {
        FileManager().createFile(atPath: path.string, contents: "\n \n".data(using: .utf8)!)
        
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }
    
    func removeFile(at path: Path) throws {
        try path.delete()
        
        try Shell.execOrFail("git add .")
        try Shell.execOrFail("git commit -m \"Change\"")
    }
    
    func createSUT(config: Config? = nil,
                   basePath: Path? = nil,
                   testPlan: String? = nil) throws -> SelectiveTestingTool {
        
        if let config {
            let configText = try config.save()
            print("config: \(configText)")
            let path = Path.current + Config.defaultConfigName
            try configText.write(toFile: path.string, atomically: true, encoding: .utf8)
        }
        
        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: basePath?.string,
                                        testPlan: testPlan,
                                        renderDependencyGraph: false,
                                        verbose: true)
    }
    
    func createSUT() throws -> SelectiveTestingTool {
    
        return try SelectiveTestingTool(baseBranch: "main",
                                        basePath: (projectPath + "ExampleWorkspace.xcworkspace").string,
                                        testPlan: "ExampleProject.xctestplan",
                                        renderDependencyGraph: false,
                                        verbose: true)
    }
    
    func validateTestPlan(testPlanPath: Path, expected: Set<TargetIdentity>) throws {
        let plan = try TestPlanHelper.readTestPlan(filePath: testPlanPath.string)
        
        let testPlanTargets: [TargetIdentity] = plan.testTargets.compactMap { target in
            let container = Path(target.target.containerPath.replacingOccurrences(of: "container:", with: ""))
            let name = target.target.name
            
            guard target.enabled ?? true else {
                return nil
            }
            
            if container.extension == "xcworkspace" || container.extension == "xcodeproj" {
                return TargetIdentity.target(projectPath: projectPath + container, name: name)
            }
            else {
                return TargetIdentity.swiftPackage(path: projectPath + container, name: name)
            }
        }
        
        XCTAssertEqual(Set(testPlanTargets), expected)
    }
    
    lazy var mainProjectMainTarget = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProject")
    lazy var mainProjectTests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectTests")
    lazy var mainProjectLibrary = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibrary")
    lazy var mainProjectLibraryTests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExmapleTargetLibraryTests")
    lazy var mainProjectUITests = TargetIdentity(projectPath: projectPath + "ExampleProject.xcodeproj", targetName: "ExampleProjectUITests")
    lazy var exampleLibrary = TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibrary")
    lazy var exampleLibraryTests = TargetIdentity(projectPath: projectPath + "ExampleLibrary/ExampleLibrary.xcodeproj", targetName: "ExampleLibraryTests")
    lazy var package = TargetIdentity.swiftPackage(path: projectPath + "ExamplePackage", name: "ExamplePackage")
    lazy var packageTests = TargetIdentity.swiftPackage(path: projectPath + "ExamplePackage", name: "ExamplePackageTests")
    lazy var subtests = TargetIdentity.swiftPackage(path: projectPath + "ExamplePackage", name: "Subtests")
    lazy var binary = TargetIdentity.swiftPackage(path: projectPath + "ExamplePackage", name: "BinaryTarget")

}
