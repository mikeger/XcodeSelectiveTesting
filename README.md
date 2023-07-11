# Xcode Selective Testing

Run only tests relevant to the changeset.

[![Swift](https://github.com/mikeger/SelectiveTesting/actions/workflows/test.yml/badge.svg)](https://github.com/mikeger/SelectiveTesting/actions/workflows/test.yml)

## What is it?

> “Insanity is doing the same thing over and over and expecting different results.”

Albert Einstein, probably

Imagine we have the following dependencies structure:

<img src="https://user-images.githubusercontent.com/715129/224667370-4121d727-ff08-427b-9ee0-75792c6e51d2.png" width="400" />

If the _📦Login_ module is changed, it would only affect the _📦LoginUI_ and the _📱MainApp_.

<img src="https://user-images.githubusercontent.com/715129/224667365-68b263bc-f5cc-4c12-8857-a74270fa0af7.png" width="400" />

Does it make sense to test all the modules if we know only the _📦Login_ module is changed? No. We can only run 50% of the tests and get the same results.

This technique saves time when testing locally and on the CI.

<img width="1206" alt="test-changed-stats-build" src="https://github.com/mikeger/SelectiveTesting/assets/715129/f114be1c-a54c-46af-8b55-de016c1fb407">

## Prerequisites

- Your project must have multiple targets or modules

## Installation

### Using Swift Package Manager

Add `.package(url: "git@github.com:mikeger/XcodeSelectiveTesting", .upToNextMajor(from: "0.5.1"))` to your `Package.swift`'s `dependencies` section.

Use SPM to run the command: `swift run xcode-selective-test`.

### Using [Mint](https://github.com/yonaskolb/Mint) (Recommended)

`mint install mikeger/XcodeSelectiveTesting@0.5.1`

### Manually

- Checkout this repository
- Compile the tool: `swift build -c release`

## Integration

### Use case: Swift Package Manager-based setup

In case you are using Swift Package Manager without Xcode project or workspace:

Run `swift test --filter "$(swift run xcode-selective-test . --json | jq -r ". | map(.name) | join(\"|\")")"`

NB: This command assumes you have [jq](https://jqlang.github.io/jq/) tool installed. You can install it with Homebrew via `brew install jq`. 

### Use case: Xcode-based project, prepare test plan locally

1. Install the tool
2. Run `mint run mikeger/XcodeSelectiveTesting@0.5.1 YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan`
3. Run tests normally, SelectiveTesting would modify your test plan according to the local changes 

### Use case: Xcode-based project, execute tests on the CI 

1. Add code to install the tool
2. Add a CI step before you execute your tests: `mint run mikeger/XcodeSelectiveTesting@0.5.1 YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan --base-branch $PR_BASE_BRANCH`
3. Execute your tests

## How does this work?

### 1. Detecting what is changed

Git allows us to find what files were touched in the changeset. 

```bash
Root
├── Dependencies
│   └── Login
│   ├── ❗️LoginAssembly.swift
│   └── ...
├── MyProject.xcodeproj
└── Sources
```

### 2. Build the dependency graph

Going from the project to its dependencies, to its dependencies, to dependencies of the dependencies, ...

Dependencies between packages can be parsed with `swift package dump-package`.

_BTW, This is the moment your Leetcode graph exercises would pay off_

### 2.5. Save the list of files for each dependency

This is important, so we'll know which files affect which targets.

### 3. Traverse the graph

Go from every changed dependency all the way up, and save a set of dependencies you've touched.

### 4. Disable tests that can be skipped in the scheme / test plan

This is the hardest part: dealing with obscure Xcode formats. But if we get that far, we will not be scared by 10-year-old XMLs.

## Command line options

- `--help`: Display all command line options
- `--base-branch`: Branch to compare against to find the relevant changes. If emitted, a local changeset is used (development mode).
- `--test-plan`: Path to the test plan. If not given, tool would try to infer the path.
- `--json`: Provide output in JSON format (STDOUT).
- `--dependency-graph`: Opens Safari with a dependency graph visualization.
- `--verbose`: Provide verbose output. 

## Configuration file `.xcode-selective-testing.yml`

It is possible to define the configuration in a separate file. The tool would look for this file in the current directory.

Options available are (see `selective-testing-config-example.yml` for an example):

- `basePath`: Relative or absolute path to the project. If set, the command line option can be emitted.
- `testPlan`: Relative or absolute path to the test plan to configure.
- `exclude`: List of relative paths to exclude when looking for Swift packages.
- `extra/dependencies`: Options allowing to hint tool about dependencies between targets or packages.
- `extra/targetsFiles`: Options allowing to hint tool about the files affecting targets or packages.

## Support

Supported operating systems:

- macOS 12.0+ (Monterey) : Xcode 14.2
- Linux: Swift 5.8

## Contributing

Contributions are welcome. Consider checking existing issues and creating a new one if you plan to contribute.

## License

See LICENSE

## Authors

- 🇺🇦 Michael Gerasymenko <mike (at) gera.cx>

If you like this product, consider donating to my hometown's charity project [Monsters Corporation](https://monstrov.org) 🤝
