# Contributing to Flutter BLOC Template

We welcome contributions to this project! To ensure a smooth and efficient process, please follow the guidelines below.

## How to Contribute
Reporting Issues

If you encounter any bugs or issues, please report them by creating a new issue in the issue tracker. Provide as much detail as possible, including steps to reproduce the issue, screenshots, and any relevant logs.

## Suggesting Enhancements

If you have ideas for improving the project, please suggest them by creating a new issue with the "Enhancement" label. Describe the enhancement in detail and explain why you believe it would be valuable.

## Submitting Code

1. Fork the Repository

    Click the "Fork" button at the top right of this repository to create your own copy.

    Clone Your Fork

    bash

git clone https://github.com/your-username/project-name.git

2. Create a Branch

Create a new branch for your changes:

bash

git checkout -b your-branch-name

3. Make Your Changes

Implement your changes in the new branch. Ensure that your code adheres to the existing code style and includes appropriate tests.

4. Commit Your Changes

Commit your changes with a descriptive message:

bash

git add .
git commit -m "Your descriptive commit message"

5. Push Your Changes

Push your changes to your fork:

bash

    git push origin your-branch-name

6. Before Pull Request !!!
- sync your fork on GitHub
- git pull on your local machine
- resolve conflicts
- run commands sequentially
    ```shell
        flutter clean
        flutter pub get
        dart run build_runner build --delete-conflicting-outputs
        dart run intl_utils:generate
        flutter analyze
        flutter test --coverage
    ```
- fix errors if needed


7. Create a Pull Request

    Navigate to the original repository and click the "New Pull Request" button. Select your branch and provide a clear description of your changes.
        Description: Provide a concise summary of what you have changed and why.
        Related Issues: Link to any related issues if applicable.

## Code Style

    Follow Dart Style Guidelines: Ensure that your code follows the Dart style guide and is properly formatted.
    Write Tests: Include tests for any new features or bug fixes.
    Documentation: Update documentation where necessary to reflect your changes.

## Review Process

    Pull requests will be reviewed by the project maintainers. Feedback will be provided, and changes may be requested.
    Maintainers will review your pull request, and if everything looks good, it will be merged into the main branch.

## Code of Conduct

By contributing to this project, you agree to adhere to our Code of Conduct.
Contact

If you have any questions, please contact us at email@example.com.

Thank you for your interest in contributing to our project!
