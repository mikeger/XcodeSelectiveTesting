# Xcode Selective Testing

Run only tests relevant to the changeset.

[Watch Video](https://www.youtube.com/watch?v=0JOX1czraGA)

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

<img width="1206" alt="test-changed-stats-build" src="https://github.com/mikeger/XcodeSelectiveTesting/assets/715129/56af05ce-72d6-4f21-a250-378b29dd215d">

## Prerequisites

- Your project must have multiple targets or modules

## Installation

### Xcode

Add to Xcode as SPM dependency.

- Open your project or workspace in Xcode
- Select yout project in the file list in Xcode
- In the right menu select "Project", open tab "Package Dependencies"
- Select "+"
- In the new window, paste `git@github.com:mikeger/XcodeSelectiveTesting` in the search field
- Select project if necessary, put a checkbox on "XcodeSelectiveTesting" in the list
- Click "Add Package"

Alternatively, you can use a prebuilt binary release of the tool distributed under [releases](https://github.com/mikeger/XcodeSelectiveTesting/releases) section.

### Using Swift Package Manager

Add `.package(url: "git@github.com:mikeger/XcodeSelectiveTesting", .upToNextMajor(from: "0.12.2"))` to your `Package.swift`'s `dependencies` section.

Use SPM to run the command: `swift run xcode-selective-test`.

Alternatively, you can use a prebuilt binary release of the tool distributed under [releases](https://github.com/mikeger/XcodeSelectiveTesting/releases) section.

### Using [Mint](https://github.com/yonaskolb/Mint)

`mint install mikeger/XcodeSelectiveTesting@0.12.2`

### Manually

- Checkout this repository
- Compile the tool: `swift build -c release`

## Integration

### Use case: Swift Package Manager-based setup

In case you are using Swift Package Manager without Xcode project or workspace:

Run `swift test --filter "$(swift run xcode-selective-test . --json | jq -r ". | map(.name) | join(\"|\")")"`

NB: This command assumes you have [jq](https://jqlang.github.io/jq/) tool installed. You can install it with Homebrew via `brew install jq`. 

### Use case: Xcode-based project, run tests locally

1. Install the tool (see [Installation: Xcode](#xcode))
2. Select your project in the Xcode's file list
3. Right-click on it and select `SelectiveTestingPlugin`
4. Wait for the tool to run
5. Run tests normally, SelectiveTesting would modify your test plan according to the local changes 

Alternatively, you can use CLI to achieve the same result:

1. Run `mint run mikeger/XcodeSelectiveTesting@0.12.2 YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan`
2. Run tests normally, XcodeSelectiveTesting would modify your test plan according to the local changes 

### Use case: Xcode-based project, execute tests on the CI, no test plan

- Requires jq installed (`brew install jq`)

1. Add code to install the tool
2. Use xcodebuild to run only selected tests: `xcodebuild test -workspace Workspace.xcworkspace -scheme Scheme $(mint run --silent XcodeSelectiveTesting@provide-if-target-is-test-target --json | jq -r "[.[] | select(.testTarget == true)] | map(\"-only-testing:\" + .name) | join(\" \")")`

### Use case: Xcode-based project, execute tests on the CI, with test plan

1. Add code to install the tool
2. Add a CI step before you execute your tests: `mint run mikeger/XcodeSelectiveTesting@0.12.2 YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan --base-branch $PR_BASE_BRANCH`
3. Execute your tests

### Use case: GitHub Actions, other cases when the git repo is not in the shape to provide the changeset out of the box

1. Add code to install the tool
2. Collect the list of changed files
3. Provide the list of changed files via the command line option `-c` or `--changed-files`

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

Dependencies between packages can be parsed with `swift package dump-package` and dependencies between Xcode projects and targets can be parsed with [XcodeProj](https://github.com/tuist/XcodeProj).

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
- `--dependency-graph`: Opens Safari with a dependency graph visualization. Attention: if you don't trust Javascript ecosystem prefer using `--dot` option. More info [here](https://github.com/mikeger/XcodeSelectiveTesting/wiki/How-to-visualize-your-dependency-structure).
- `--dot`: Output dependency graph in Dot (Graphviz) format. To be used with Graphviz: `brew install graphviz`, then `xcode-selective-test --dot | dot -Tsvg > output.svg && open output.svg`
- `--turbo`: Turbo mode: run tests only for directly affected targets.
- `--verbose`: Provide verbose output.
- `-c, --changed-files`: Provides the list of changed files to take in account. Do not attempt to calculate the changeset.

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

- macOS 12.0+ (Monterey) : Xcode 14.2 and above
- Linux: Swift 5.8 and above

## Contributing

Contributions are welcome. Consider checking existing issues and creating a new one if you plan to contribute.

## License

See LICENSE

## Authors

- 🇺🇦 Michael Gerasymenko <mike (at) gera.cx>

## Contributors

- [Sam Woolf](https://github.com/swwol)
- [fxwx23](https://github.com/fxwx23)
- [Ashutosh Dubey](https://github.com/dev-ashuDubey)
- [Bruno Guidolim](https://github.com/bguidolim)
- [Alex Deem](https://github.com/alexdeem)
- [Steffen Matthischke](https://github.com/HeEAaD)
- [Econa77](https://github.com/Econa77)

If you like this product, consider donating to my hometown's charity project [Monsters Corporation](https://monstrov.org) 🤝
