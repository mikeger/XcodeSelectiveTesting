//
//  Created by Mike Gerasymenko <mike@gera.cx>
//

import XCTest
@testable import Workspace

final class ChangesetMetadataTests: XCTestCase {
    func testOutputParsing() {
        let sampleOutput = """
 Package.swift                                                   |  3 +++
 Sources/DependencyCalculator/DependencyCalculator.swift         |  2 +-
 Sources/DependencyCalculator/DependencyGraph.swift              |  8 ++++----
 Sources/DependencyCalculator/PackageMetadata.swift              |  8 ++++----
 Sources/Git/ChangesetMetadata.swift                             | 40 ++++++++++++++++++++++++++++++++++++++++
 Sources/Git/Git+Changeset.swift                                 | 18 +++++++++++-------
 Sources/SelectiveTestingCore/SelectiveTestingTool.swift         | 22 +++++++++++-----------
 Sources/TestConfigurator/TestConfigurator.swift                 | 16 ++++++++--------
 Sources/Workspace/Target.swift                                  | 63 +++++++++++++++++----------------------------------------------
 Tests/DependencyCalculatorTests/DependencyCalculatorTests.swift | 12 ++++++------
 Tests/DependencyCalculatorTests/PackageMetadataTests.swift      | 16 +++++++---------
 Tests/GitTests/GitTests.swift                                   | 33 +++++++++++++++++++++++++++++++++
 Tests/SelectiveTestingTests/IntegrationTestTool.swift           | 28 ++++++++++++++--------------
 13 files changed, 159 insertions(+), 110 deletions(-)
"""
        
        let data = sampleOutput.components(separatedBy: .newlines).compactMap { line in
            ChangesetMetadata(gitStatOutput: line)
        }
        
        XCTAssertEqual(data.count, 13)
        XCTAssertEqual(data, [ChangesetMetadata(path: "Package.swift", changedLines: 3),
                              ChangesetMetadata(path: "Sources/DependencyCalculator/DependencyCalculator.swift", changedLines: 2),
                              ChangesetMetadata(path: "Sources/DependencyCalculator/DependencyGraph.swift", changedLines: 8),
                              ChangesetMetadata(path: "Sources/DependencyCalculator/PackageMetadata.swift", changedLines: 8),
                              ChangesetMetadata(path: "Sources/Git/ChangesetMetadata.swift", changedLines: 40),
                              ChangesetMetadata(path: "Sources/Git/Git+Changeset.swift", changedLines: 18),
                              ChangesetMetadata(path: "Sources/SelectiveTestingCore/SelectiveTestingTool.swift", changedLines: 22),
                              ChangesetMetadata(path: "Sources/TestConfigurator/TestConfigurator.swift", changedLines: 16),
                              ChangesetMetadata(path: "Sources/Workspace/Target.swift", changedLines: 63),
                              ChangesetMetadata(path: "Tests/DependencyCalculatorTests/DependencyCalculatorTests.swift", changedLines: 12),
                              ChangesetMetadata(path: "Tests/DependencyCalculatorTests/PackageMetadataTests.swift", changedLines: 16),
                              ChangesetMetadata(path: "Tests/GitTests/GitTests.swift", changedLines: 33),
                              ChangesetMetadata(path: "Tests/SelectiveTestingTests/IntegrationTestTool.swift", changedLines: 28),
                             ])
    }
}
