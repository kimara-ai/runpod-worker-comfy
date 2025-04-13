# Python Testing Guide for RunPod Worker ComfyUI

This guide explains how to run Python tests for the RunPod Worker ComfyUI project.

## Prerequisites

- Python 3.10 or higher
- Git clone of the repository

## Setting Up the Test Environment

1. **Create a Virtual Environment**

   ```bash
   python -m venv venv
   ```

2. **Activate the Virtual Environment**

   - **Linux/macOS**:
     ```bash
     source ./venv/bin/activate
     ```
   
   - **Windows**:
     ```bash
     .\venv\Scripts\activate
     ```

3. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

## Running the Tests

### Running All Tests

To run all tests in the project:

```bash
python -m unittest discover
```

This command will:
- Discover all test files in the `tests/` directory that match the pattern `test_*.py`
- Execute all test methods in those files
- Display the test results in the console

### Running Specific Tests

To run a specific test file:

```bash
python -m unittest tests.test_rp_handler
```

To run a specific test case class:

```bash
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy
```

To run a specific test method:

```bash
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy.test_bucket_endpoint_not_configured
```

## Test Structure

The project uses Python's built-in `unittest` framework. Key aspects of the test suite include:

- **Mock Objects**: The tests use Python's `unittest.mock` to mock external services and dependencies
- **Environment Variables**: Tests simulate different configurations by setting environment variables
- **Test Resources**: The tests use resources in the `test_resources/` directory

## Adding New Tests

When adding new tests:

1. Create test methods in the appropriate test class in `tests/test_rp_handler.py`
2. Follow the naming convention `test_*` for test methods
3. Use appropriate assertions based on the expected behavior
4. Use mocks for external dependencies
5. If necessary, use `setUp` and `tearDown` methods for test initialization and cleanup

## Common Test Cases

The test suite covers various scenarios, including:

- **Input Validation**: Tests that validate different types of input data
- **Server Connectivity**: Tests that check the server connection functionality
- **Image Processing**: Tests that verify the image processing and storage options
- **Storage Options**: Tests for different storage backends (base64, S3, Azure)
- **Error Handling**: Tests for handling failures gracefully

## Test Coverage

To run the tests with coverage reporting:

```bash
pip install coverage
coverage run -m unittest discover
coverage report
```

This will show you how much of the codebase is covered by the tests.

## Troubleshooting

- **Import Errors**: Ensure your virtual environment is activated and all dependencies are installed
- **Path Issues**: The test suite modifies `sys.path` to import the `src` module properly
- **Mock Issues**: If tests fail due to mocking issues, ensure you're mocking the correct objects and methods
- **Resource Not Found**: Make sure the test resources exist in the expected locations