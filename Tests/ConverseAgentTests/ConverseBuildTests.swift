import Foundation
import XCTest
@testable import ConverseAgent

/// The kit compiled and run as apps would: written into a package of three apps (Seer from its example call, its types
/// in a SeerKit package of their own, Swift 6; a tutor from the other example call, prefixed, Swift 5; the least call,
/// Swift 6), each with the page body a host would write. Built with `swift build` for the Mac, every root view drawn
/// offscreen from each app's own values, then built with `xcodebuild` for the iPhone simulator.
/// Gated (`CONVERSE_BUILD=1`): the builds take a minute or more. `CONVERSE_KEEP=<folder>` writes the package there,
/// `CONVERSE_SHOTS=<folder>` saves each drawn view there in light and dark.
final class ConverseBuildTests: XCTestCase {
    func testTheKitBuildsForMacAndIPhoneInBothLanguageModesAndEveryRootViewDraws() throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["CONVERSE_BUILD"] == "1", "set CONVERSE_BUILD=1 to build the output")
        let package: URL
        if let keep = environment["CONVERSE_KEEP"] {
            package = URL(fileURLWithPath: keep, isDirectory: true)
            try? FileManager.default.removeItem(at: package)
            try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
        } else {
            package = try Fixture.folder()
        }
        func put(_ text: String, _ path: String) throws {
            let url = package.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }

        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(
            name: "ConverseApps",
            platforms: [.iOS(.v17), .macOS(.v14)],
            products: [.library(name: "ConverseApps", targets: ["Seer", "Tutor", "Least"])],
            targets: [
                .target(name: "SeerKit", swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "Seer", dependencies: ["SeerKit"], swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "Tutor", swiftSettings: [.swiftLanguageMode(.v5)]),
                .target(name: "Least", swiftSettings: [.swiftLanguageMode(.v6)]),
                .executableTarget(name: "Check", dependencies: ["Seer", "Tutor", "Least"], swiftSettings: [.swiftLanguageMode(.v6)]),
            ]
        )
        """.write(to: package.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        // The app's own files first, so the call reads its types as an app's would be read.
        try put(ConverseApps.seerKit, "Sources/SeerKit/Models.swift")
        try put(ConverseApps.seerDesign, "Sources/Seer/Design.swift")
        try put(ConverseApps.seerPage, "Sources/Seer/Seer.swift")
        try put(ConverseApps.draw.replacingOccurrences(of: "__PREFIX__", with: "Converse"), "Sources/Seer/Draw.swift")
        try put(ConverseApps.tutorModels, "Sources/Tutor/Models.swift")
        try put(ConverseApps.tutorPage, "Sources/Tutor/TutorPage.swift")
        try put(ConverseApps.draw.replacingOccurrences(of: "__PREFIX__", with: "Tutor"), "Sources/Tutor/Draw.swift")
        try put(ConverseApps.leastPage, "Sources/Least/LeastPage.swift")
        try put(ConverseApps.draw.replacingOccurrences(of: "__PREFIX__", with: "Converse"), "Sources/Least/Draw.swift")
        try put("""
        import Foundation
        import Seer
        import Tutor
        import Least

        let results = MainActor.assumeIsolated { [SeerCheck.run(), TutorCheck.run(), LeastCheck.run()] }
        let failed = results.flatMap(\\.failed)
        print("drew \\(results.flatMap(\\.drawn).count) views")
        if !failed.isEmpty {
            print("did not draw: \\(failed)")
            exit(1)
        }
        """, "Sources/Check/main.swift")

        var seer = try Fixture.example("seer")
        seer.into = "Sources/Seer/Components/Converse"
        seer.directory = package.path
        let seerResult = try ConverseAgent.write(seer, note: { _ in }, yield: { _ in })
        XCTAssertTrue(seerResult.paths.contains { $0.hasSuffix("/Conformances/Exchange+ConverseExchange.swift") })
        XCTAssertTrue(try Fixture.text(seerResult.paths, "Exchange+ConverseExchange.swift").contains("import SeerKit"))

        var tutor = try Fixture.example("tutor")
        tutor.into = "Sources/Tutor/Views/Tutor"
        tutor.directory = package.path
        let tutorResult = try ConverseAgent.write(tutor, note: { _ in }, yield: { _ in })
        XCTAssertFalse(try Fixture.text(tutorResult.paths, "Turn+TutorExchange.swift").contains("import Tutor"),
                       "a type declared in the kit's own module is not imported")

        let least = try ConverseAgent.write(.init(into: "Sources/Least/Components/Converse", directory: package.path), note: { _ in }, yield: { _ in })
        XCTAssertGreaterThan(seerResult.paths.count + tutorResult.paths.count + least.paths.count, 70)

        // The Mac: every target, Swift 6 and Swift 5, with no warning in what the kit wrote.
        let mac = try run(["swift", "build", "--package-path", package.path])
        XCTAssertEqual(mac.status, 0, String(mac.log.suffix(6_000)))
        let warnings = mac.log.split(separator: "\n").filter {
            ($0.contains("/Components/Converse/") || $0.contains("/Views/Tutor/")) && $0.contains("warning:")
        }
        XCTAssertTrue(warnings.isEmpty, warnings.joined(separator: "\n"))

        // Every root view made from each app's own values and drawn: nothing traps.
        let drawn = try run(["swift", "run", "--package-path", package.path, "Check"])
        XCTAssertEqual(drawn.status, 0, String(drawn.log.suffix(4_000)))
        XCTAssertNotNil(drawn.log.range(of: #"drew \d{2,} views"#, options: .regularExpression), drawn.log)

        // The iPhone simulator.
        let phone = try run(["xcodebuild", "-scheme", "ConverseApps", "-destination", "generic/platform=iOS Simulator",
                             "-derivedDataPath", package.appendingPathComponent("dd").path,
                             "-skipPackagePluginValidation", "-skipMacroValidation", "build"], in: package)
        XCTAssertTrue(phone.log.contains("** BUILD SUCCEEDED **"), String(phone.log.suffix(6_000)))
        let phoneWarnings = phone.log.split(separator: "\n").filter {
            ($0.contains("/Components/Converse/") || $0.contains("/Views/Tutor/")) && $0.contains("warning:")
        }
        XCTAssertTrue(phoneWarnings.isEmpty, Set(phoneWarnings).sorted().joined(separator: "\n"))
    }

    private func run(_ arguments: [String], in folder: URL? = nil) throws -> (status: Int32, log: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        if let folder { process.currentDirectoryURL = folder }
        let out = Pipe()
        process.standardOutput = out
        process.standardError = out
        try process.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
