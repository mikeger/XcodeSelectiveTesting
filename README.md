# Xcode Selective Testing

Run only tests relevant for the changeset.

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
- Xcode-based project
- Use of TestPlans

## Installation

### Using [Mint](https://github.com/yonaskolb/Mint) (Recommended)

`mint install mikeger/XcodeSelectiveTesting@main`

### Manually

- Checkout this repository
- Compile the tool: `swift build -c release`
- Run: `./.build/release/xcode-selective-test your-branch Workspace.xcworkspace TestPlan.xctestplan`

## Integration

### Use case: prepare test plan locally

1. Install the tool
2. Run `mint run mikeger/XcodeSelectiveTesting@main YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan`
3. Run tests normally, SelectiveTesting would modify your test plan according to the local changes 

### Use case: execute tests on the CI 

1. Add code to install the tool
2. Add a CI step before you execute your tests: `mint run mikeger/XcodeSelectiveTesting@main YourWorkspace.xcworkspace --test-plan YourTestPlan.xctestplan --base-branch $PR_BASE_BRANCH`
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

This is actually the hardest part. Dealing with obscure Xcode formats. But if we get that far, we will not be scared by 10-year-old XMLs.

## Command line options

- `--help`: Display all command line options
- `--base-branch`: Branch to compare against to find the relevant changes. If emitted, a local changeset is used (development mode).
- `--test-plan`: Path to the test plan. If not given, tool would try to infer the path.
- `--print-json`: Provide output in JSON format (STDOUT).
- `--render-dependency-graph`: Opens Safari with a dependency graph visualization.
- `--verbose`: Provide verbose output. 

## Configuration file `.xcode-selective-testing.yml`

It is possible to define the configuration in a separate file. The tool would look for this file in the current directory.

Options available are (see `selective-testing-config-example.yml` as example):

- `projectOrWorkspace`: Relative or absolute path to the project. If set, the command line option can be emitted.
- `testPlan`: Relative or absolute path to the test plan to configure.
- `extra/dependencies`: Options allowing to hint tool about dependencies between targets or packages.
- `extra/targetsFiles`: Options allowing to hint tool about the files affecting targets or packages.

## Known limitations

### Swift packages

- Tool is not taking in consideration different targets in the package, i.e. it is looking on the package as on a single testable entity.
- A setup without Xcode project or workspace is currently not supported.

## Contributing

Contributions are welcome. Consider checking existing issues and creating a new one if you plan to contribute.

## License

See LICENSE

