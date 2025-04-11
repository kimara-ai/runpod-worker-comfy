import unittest
from unittest.mock import patch, MagicMock, mock_open, Mock
import sys
import os
import json
import base64

# Make sure that "src" is known and can be used to import rp_handler.py
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

# Mock the runpod module as it's not needed for tests
sys.modules['runpod'] = MagicMock()
sys.modules['runpod.serverless.utils'] = MagicMock()
sys.modules['runpod.serverless.utils.rp_upload'] = MagicMock()
sys.modules['azure.storage.blob'] = MagicMock()
sys.modules['azure.identity'] = MagicMock()

from src import rp_handler

# Local folder for test resources
RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES = "./test_resources/images"


class TestRunpodWorkerComfy(unittest.TestCase):
    def test_valid_input_with_workflow_only(self):
        input_data = {"workflow": {"key": "value"}}
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNone(error)
        self.assertEqual(validated_data, {"workflow": {"key": "value"}, "images": None})

    def test_valid_input_with_workflow_and_images(self):
        input_data = {
            "workflow": {"key": "value"},
            "images": [{"name": "image1.png", "image": "base64string"}],
        }
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNone(error)
        self.assertEqual(validated_data, input_data)

    def test_input_missing_workflow(self):
        input_data = {"images": [{"name": "image1.png", "image": "base64string"}]}
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNotNone(error)
        self.assertEqual(error, "Missing 'workflow' parameter")

    def test_input_with_invalid_images_structure(self):
        input_data = {
            "workflow": {"key": "value"},
            "images": [{"name": "image1.png"}],  # Missing 'image' key
        }
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNotNone(error)
        self.assertEqual(
            error, "'images' must be a list of objects with 'name' and 'image' keys"
        )

    def test_invalid_json_string_input(self):
        input_data = "invalid json"
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNotNone(error)
        self.assertEqual(error, "Invalid JSON format in input")

    def test_valid_json_string_input(self):
        input_data = '{"workflow": {"key": "value"}}'
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNone(error)
        self.assertEqual(validated_data, {"workflow": {"key": "value"}, "images": None})

    def test_empty_input(self):
        input_data = None
        validated_data, error = rp_handler.validate_input(input_data)
        self.assertIsNotNone(error)
        self.assertEqual(error, "Please provide input")

    @patch("rp_handler.requests.get")
    def test_check_server_server_up(self, mock_requests):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_requests.return_value = mock_response

        result = rp_handler.check_server("http://127.0.0.1:8188", 1, 50)
        self.assertTrue(result)

    @patch("rp_handler.requests.get")
    def test_check_server_server_down(self, mock_requests):
        mock_requests.get.side_effect = rp_handler.requests.RequestException()
        result = rp_handler.check_server("http://127.0.0.1:8188", 1, 50)
        self.assertFalse(result)

    @patch("rp_handler.urllib.request.urlopen")
    def test_queue_prompt(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"prompt_id": "123"}).encode()
        mock_urlopen.return_value = mock_response
        result = rp_handler.queue_workflow({"prompt": "test"})
        self.assertEqual(result, {"prompt_id": "123"})

    @patch("rp_handler.urllib.request.urlopen")
    def test_get_history(self, mock_urlopen):
        # Mock response data as a JSON string
        mock_response_data = json.dumps({"key": "value"}).encode("utf-8")

        # Define a mock response function for `read`
        def mock_read():
            return mock_response_data

        # Create a mock response object
        mock_response = Mock()
        mock_response.read = mock_read

        # Mock the __enter__ and __exit__ methods to support the context manager
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = Mock()

        # Set the return value of the urlopen mock
        mock_urlopen.return_value = mock_response

        # Call the function under test
        result = rp_handler.get_history("123")

        # Assertions
        self.assertEqual(result, {"key": "value"})
        mock_urlopen.assert_called_with("http://127.0.0.1:8188/history/123")

    @patch("builtins.open", new_callable=mock_open, read_data=b"test")
    def test_base64_encode(self, mock_file):
        test_data = base64.b64encode(b"test").decode("utf-8")

        result = rp_handler.base64_encode("dummy_path")

        self.assertEqual(result, test_data)

    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.base64_encode")
    @patch.dict(
        os.environ, {"COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES}
    )
    def test_bucket_endpoint_not_configured(self, mock_base64_encode, mock_exists):
        mock_exists.return_value = True
        mock_base64_encode.return_value = "base64_encoded_image_data"

        outputs = {
            "node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": ""}]}
        }
        job_id = "123"

        result = rp_handler.process_output_images(outputs, job_id)

        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "base64")
        self.assertEqual(result["message"][0]["image"], "base64_encoded_image_data")

    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.rp_upload.upload_image")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "BUCKET_ENDPOINT_URL": "http://example.com",
            "IMAGE_RETURN_METHOD": "s3",
        },
    )
    def test_bucket_endpoint_configured(self, mock_upload_image, mock_exists):
        # Mock the os.path.exists to return True, simulating that the image exists
        mock_exists.return_value = True

        # Mock the rp_upload.upload_image to return a simulated URL
        mock_upload_image.return_value = "http://example.com/uploaded/image.png"

        # Define the outputs and job_id for the test
        outputs = {"node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": "test"}]}}
        job_id = "123"

        # Call the function under test
        result = rp_handler.process_output_images(outputs, job_id)

        # Assertions
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "url")
        self.assertEqual(result["message"][0]["image"], "http://example.com/uploaded/image.png")
        mock_upload_image.assert_called_once_with(
            job_id, "./test_resources/images/test/ComfyUI_00001_.png"
        )
        
    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.upload_to_azure_blob")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "AZURE_STORAGE_CONNECTION_STRING": "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=accountkey;EndpointSuffix=core.windows.net",
            "IMAGE_RETURN_METHOD": "azure",
        },
    )
    def test_azure_blob_storage_configured(self, mock_upload_to_azure, mock_exists):
        # Mock the os.path.exists to return True, simulating that the image exists
        mock_exists.return_value = True

        # Mock the upload_to_azure_blob to return a simulated URL
        mock_upload_to_azure.return_value = "https://mystorageaccount.blob.core.windows.net/comfyui-images/123/ComfyUI_00001_.png"

        # Define the outputs and job_id for the test
        outputs = {"node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": "test"}]}}
        job_id = "123"

        # Call the function under test
        result = rp_handler.process_output_images(outputs, job_id)

        # Assertions
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "url")
        self.assertEqual(result["message"][0]["image"], "https://mystorageaccount.blob.core.windows.net/comfyui-images/123/ComfyUI_00001_.png")
        mock_upload_to_azure.assert_called_once_with(
            job_id, "./test_resources/images/test/ComfyUI_00001_.png"
        )
        
    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.upload_to_azure_blob")
    @patch("rp_handler.base64_encode")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "AZURE_STORAGE_CONNECTION_STRING": "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=accountkey;EndpointSuffix=core.windows.net",
            "IMAGE_RETURN_METHOD": "azure",
        },
    )
    def test_azure_blob_storage_upload_fails(self, mock_base64_encode, mock_upload_to_azure, mock_exists):
        # Mock the os.path.exists to return True, simulating that the image exists
        mock_exists.return_value = True

        # Mock the upload_to_azure_blob to return None, simulating a failure
        mock_upload_to_azure.return_value = None
        
        # Mock the base64_encode to return a simulated base64 string
        mock_base64_encode.return_value = "base64encodedstring"

        # Define the outputs and job_id for the test
        outputs = {"node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": "test"}]}}
        job_id = "123"

        # Call the function under test
        result = rp_handler.process_output_images(outputs, job_id)

        # Assertions
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "base64")
        self.assertEqual(result["message"][0]["image"], "base64encodedstring")
        mock_upload_to_azure.assert_called_once_with(
            job_id, "./test_resources/images/test/ComfyUI_00001_.png"
        )
        mock_base64_encode.assert_called_once_with(
            "./test_resources/images/test/ComfyUI_00001_.png"
        )

    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.rp_upload.upload_image")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "BUCKET_ENDPOINT_URL": "http://example.com",
            "BUCKET_ACCESS_KEY_ID": "",
            "BUCKET_SECRET_ACCESS_KEY": "",
        },
    )
    def test_bucket_image_upload_fails_env_vars_wrong_or_missing(
        self, mock_upload_image, mock_exists
    ):
        # Simulate the file existing in the output path
        mock_exists.return_value = True

        # When AWS credentials are wrong or missing, upload_image should return 'simulated_uploaded/...'
        mock_upload_image.return_value = "simulated_uploaded/image.png"

        outputs = {
            "node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": ""}]}
        }
        job_id = "123"

        result = rp_handler.process_output_images(outputs, job_id)

        # Assertions for the new format
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "url")
        self.assertIn("simulated_uploaded", result["message"][0]["image"])

    @patch("rp_handler.requests.post")
    def test_upload_images_successful(self, mock_post):
        mock_response = unittest.mock.Mock()
        mock_response.status_code = 200
        mock_response.text = "Successfully uploaded"
        mock_post.return_value = mock_response

        test_image_data = base64.b64encode(b"Test Image Data").decode("utf-8")

        images = [{"name": "test_image.png", "image": test_image_data}]

        responses = rp_handler.upload_images(images)

        self.assertEqual(len(responses), 3)
        self.assertEqual(responses["status"], "success")

    @patch("rp_handler.requests.post")
    def test_upload_images_failed(self, mock_post):
        mock_response = unittest.mock.Mock()
        mock_response.status_code = 400
        mock_response.text = "Error uploading"
        mock_post.return_value = mock_response

        test_image_data = base64.b64encode(b"Test Image Data").decode("utf-8")

        images = [{"name": "test_image.png", "image": test_image_data}]

        responses = rp_handler.upload_images(images)

        self.assertEqual(len(responses), 3)
        self.assertEqual(responses["status"], "error")
        
    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.base64_encode")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "IMAGE_RETURN_METHOD": "base64",
        },
    )
    def test_default_base64_method(self, mock_base64_encode, mock_exists):
        # Mock the os.path.exists to return True, simulating that the image exists
        mock_exists.return_value = True
        
        # Mock the base64_encode to return a simulated base64 string
        mock_base64_encode.return_value = "base64encodedstring"
        
        # Define the outputs and job_id for the test
        outputs = {"node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": "test"}]}}
        job_id = "123"
        
        # Call the function under test
        result = rp_handler.process_output_images(outputs, job_id)
        
        # Assertions
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "base64")
        self.assertEqual(result["message"][0]["image"], "base64encodedstring")
        mock_base64_encode.assert_called_once_with(
            "./test_resources/images/test/ComfyUI_00001_.png"
        )

    @patch("rp_handler.os.path.exists")
    @patch("rp_handler.base64_encode")
    @patch.dict(
        os.environ,
        {
            "COMFY_OUTPUT_PATH": RUNPOD_WORKER_COMFY_TEST_RESOURCES_IMAGES,
            "IMAGE_RETURN_METHOD": "azure",
        },
    )
    def test_cloud_storage_requested_but_not_configured(self, mock_base64_encode, mock_exists):
        # Mock the os.path.exists to return True, simulating that the image exists
        mock_exists.return_value = True
        
        # Mock the base64_encode to return a simulated base64 string
        mock_base64_encode.return_value = "base64encodedstring"
        
        # Define the outputs and job_id for the test
        outputs = {"node_id": {"images": [{"filename": "ComfyUI_00001_.png", "subfolder": "test"}]}}
        job_id = "123"
        
        # Call the function under test
        result = rp_handler.process_output_images(outputs, job_id)
        
        # Assertions
        self.assertEqual(result["status"], "success")
        self.assertIsInstance(result["message"], list)
        self.assertEqual(len(result["message"]), 1)
        self.assertEqual(result["message"][0]["node_id"], "node_id")
        self.assertEqual(result["message"][0]["imageType"], "base64")
        self.assertEqual(result["message"][0]["image"], "base64encodedstring")
        mock_base64_encode.assert_called_once_with(
            "./test_resources/images/test/ComfyUI_00001_.png"
        )

    @patch("builtins.open", new_callable=mock_open, read_data=b"test_image_data")
    @patch("rp_handler.BlobServiceClient.from_connection_string")
    @patch.dict(
        os.environ,
        {
            "AZURE_STORAGE_CONNECTION_STRING": "DefaultEndpointsProtocol=https;AccountName=mystorageaccount;AccountKey=accountkey;EndpointSuffix=core.windows.net",
        },
    )
    def test_upload_to_azure_blob(self, mock_blob_service_client, mock_file):
        # Setup mocks for the Azure blob storage
        mock_container_client = MagicMock()
        mock_container_client.exists.return_value = True
        
        mock_blob_client = MagicMock()
        mock_blob_client.url = "https://mystorageaccount.blob.core.windows.net/comfyui-images/job123/image.png"
        
        mock_blob_service = MagicMock()
        mock_blob_service.get_container_client.return_value = mock_container_client
        mock_blob_service.get_blob_client.return_value = mock_blob_client
        
        mock_blob_service_client.return_value = mock_blob_service

        # Run the function
        result = rp_handler.upload_to_azure_blob("job123", "/path/to/image.png")
        
        # Assertions
        self.assertEqual(result, "https://mystorageaccount.blob.core.windows.net/comfyui-images/job123/image.png")
        mock_blob_service.get_container_client.assert_called_once()
        mock_blob_service.get_blob_client.assert_called_once()
        mock_blob_client.upload_blob.assert_called_once()