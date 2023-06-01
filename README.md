# SelectiveTesting

[![Swift](https://github.com/mikeger/SelectiveTesting/actions/workflows/test.yml/badge.svg)](https://github.com/mikeger/SelectiveTesting/actions/workflows/test.yml)

## What is it?

> “Insanity is doing the same thing over and over and expecting different results.”

Albert Einstein, probably

Imagine we have the following dependencies structure:

<img src="https://user-images.githubusercontent.com/715129/224667370-4121d727-ff08-427b-9ee0-75792c6e51d2.png" width="400" />

If the _📦Login_ module is changed, it would only affect the _📦LoginUI_ and the _📱MainApp_.

<img src="https://user-images.githubusercontent.com/715129/224667365-68b263bc-f5cc-4c12-8857-a74270fa0af7.png" width="400" />

Does it make sense to test all the modules if we know only the _📦Login_ module is changed? No. We can only run 50% of the tests and get the same results.

## Prerequisites

- Your project must have multiple targets.
- Xcode-based project 
- Use of TestPlans 

## Installation

- Checkout this repository
- Compile the tool: `swift build -c release`
- Run: `./.build/release/SelectiveTesting your-branch Workspace.xcworkspace TestPlan.xctestplan`

## Integration

1. Install the tool
2. Run the tool so that it can configure the Test Plan
3. Run tests in the same scheme where a Test Plan is configured

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

## TODO

- More extensive testing:
 - Project-only scenario
 - Case when a file is added / deleted to a SPM package
- Generate report

## Contributing

Contributions are welcome. Consider checking existing issues and creating a new one if you plan to contribute.

## License

See LICENSE

