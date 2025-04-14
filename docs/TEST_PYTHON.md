# Python Testing Guide for RunPod Worker ComfyUI

This comprehensive guide explains how to set up, run, and extend the Python tests for the RunPod Worker ComfyUI project.

## Prerequisites

- Python 3.10+
- Git
- Bash/Terminal (Windows users: Git Bash or WSL recommended)

## Setting Up Your Test Environment

### 1. Create a Virtual Environment

```bash
python -m venv venv
```

### 2. Activate the Environment

**Linux/macOS**:
```bash
source ./venv/bin/activate
```

**Windows**:
```bash
.\venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

## Running Tests

### Basic Test Execution

```bash
# Run all tests
python -m unittest discover

# Run tests with verbose output
python -m unittest discover -v
```

### Running Specific Tests

```bash
# Run a specific test file
python -m unittest tests.test_rp_handler

# Run a specific test class
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy

# Run a specific test method
python -m unittest tests.test_rp_handler.TestRunpodWorkerComfy.test_bucket_endpoint_not_configured
```

### Test Coverage

Measure code coverage to identify untested areas:

```bash
# Install coverage tool
pip install coverage

# Run tests with coverage
coverage run -m unittest discover

# View coverage report
coverage report

# Generate HTML report (creates htmlcov/ directory)
coverage html
```

## Test Structure

### Framework & Organization

- **Framework**: Python's built-in `unittest`
- **Test Location**: All tests reside in the `tests/` directory
- **Naming Convention**: Test files follow the `test_*.py` pattern
- **Primary Test File**: `tests/test_rp_handler.py`

### Key Testing Components

- **Mock Objects**: Uses `unittest.mock` to simulate external services
- **Environment Variables**: Configures different runtime environments
- **Test Resources**: Leverages fixtures from `test_resources/` directory
- **Test Data**: Uses workflow files in `test_resources/workflows/`

## Test Best Practices

- **Isolation**: Each test runs independently
- **Setup/Teardown**: Use `setUp()` and `tearDown()`
- **Names**: Clear descriptive method names
- **Assertions**: Include helpful messages
- **Focus**: One feature per test

```python
def test_feature_condition(self):
    # Setup
    self.mock_service.return_value = expected_value
    os.environ["TEST_CONFIG"] = "test_value"
    
    # Run
    result = self.handler.process_something()
    
    # Verify
    self.assertEqual(result, expected_value)
    
    # Cleanup
    os.environ.pop("TEST_CONFIG", None)
```

## Test Categories

The test suite covers:

- **Input Validation**: API inputs testing
- **Server Connectivity**: ComfyUI API tests
- **Image Processing**: Image generation tests
- **Storage Backends**: Storage options tests (base64/S3/Azure)
- **Error Handling**: Error recovery tests

## Adding New Tests

To add a new test:

1. Identify the feature or scenario to test
2. Create a test method in the appropriate class in `tests/test_rp_handler.py`
3. Follow the naming convention: `test_<feature>_<scenario>()`
4. Mock any external dependencies
5. Use appropriate assertions to verify expected behavior
6. Add any needed test resources to `test_resources/`

## Troubleshooting

Common issues when running tests:

- **Import errors**: Check virtual environment activation
- **ModuleNotFoundError**: Test setup should add `src` directory to `sys.path`
- **Mock issues**: Verify correct paths and return values
- **Resource errors**: Confirm test resources exist
- **Environment variable conflicts**: Clean up in `tearDown()`

## Advanced Techniques

### Environment Variables

```python
original_env = os.environ.get("FEATURE_FLAG", None)
os.environ["FEATURE_FLAG"] = "enabled"
try:
    result = feature_under_test()
    self.assertTrue(result)
finally:
    if original_env is None:
        os.environ.pop("FEATURE_FLAG", None)
    else:
        os.environ["FEATURE_FLAG"] = original_env
```

### Async Testing

```python
import asyncio

def test_async_function(self):
    result = asyncio.run(self.async_function_under_test())
    self.assertEqual(result, expected_value)
```

### Parameterized Tests

```python
test_cases = [
    ("case1", input1, expected1),
    ("case2", input2, expected2)
]

for case_name, test_input, expected in test_cases:
    with self.subTest(case=case_name):
        result = function_under_test(test_input)
        self.assertEqual(result, expected)
```