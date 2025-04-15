import runpod
from runpod.serverless.utils import rp_upload
import json
import urllib.request
import urllib.parse
import time
import os
import requests
import base64
import uuid
from io import BytesIO
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
from azure.identity import DefaultAzureCredential

# Time to wait between API check attempts in milliseconds
COMFY_API_AVAILABLE_INTERVAL_MS = 50
# Maximum number of API check attempts
COMFY_API_AVAILABLE_MAX_RETRIES = 500
# Time to wait between poll attempts in milliseconds
COMFY_POLLING_INTERVAL_MS = int(os.environ.get("COMFY_POLLING_INTERVAL_MS", 250))
# Maximum number of poll attempts
COMFY_POLLING_MAX_RETRIES = int(os.environ.get("COMFY_POLLING_MAX_RETRIES", 500))
# Host where ComfyUI is running
COMFY_HOST = "127.0.0.1:8188"
# Enforce a clean state after each job is done
# see https://docs.runpod.io/docs/handler-additional-controls#refresh-worker
REFRESH_WORKER = os.environ.get("REFRESH_WORKER", "false").lower() == "true"


def validate_input(job_input):
    """
    Validates the input for the handler function.

    Args:
        job_input (dict): The input data to validate.

    Returns:
        tuple: A tuple containing the validated data and an error message, if any.
               The structure is (validated_data, error_message).
    """
    # Validate if job_input is provided
    if job_input is None:
        return None, "Please provide input"

    # Check if input is a string and try to parse it as JSON
    if isinstance(job_input, str):
        try:
            job_input = json.loads(job_input)
        except json.JSONDecodeError:
            return None, "Invalid JSON format in input"

    # Validate 'workflow' in input
    workflow = job_input.get("workflow")
    if workflow is None:
        return None, "Missing 'workflow' parameter"

    # Validate 'images' in input, if provided
    images = job_input.get("images")
    if images is not None:
        if not isinstance(images, list) or not all(
            "name" in image and "image" in image for image in images
        ):
            return (
                None,
                "'images' must be a list of objects with 'name' and 'image' keys",
            )

    # Return validated data and no error
    return {"workflow": workflow, "images": images}, None


def check_server(url, retries=500, delay=50):
    """
    Check if a server is reachable via HTTP GET request

    Args:
    - url (str): The URL to check
    - retries (int, optional): The number of times to attempt connecting to the server. Default is 500
    - delay (int, optional): The time in milliseconds to wait between retries. Default is 50

    Returns:
    bool: True if the server is reachable within the given number of retries, otherwise False
    """

    for i in range(retries):
        try:
            response = requests.get(url)

            # If the response status code is 200, the server is up and running
            if response.status_code == 200:
                print(f"runpod-worker-comfy - API is reachable after {i+1} attempts")
                return True
        except requests.RequestException as e:
            # If an exception occurs, the server may not be ready
            pass

        # Wait for the specified delay before retrying
        time.sleep(delay / 1000)

    print(
        f"runpod-worker-comfy - Failed to connect to server at {url} after {retries} attempts."
    )
    return False


def upload_images(images):
    """
    Upload a list of base64 encoded images to the ComfyUI server using the /upload/image endpoint.

    Args:
        images (list): A list of dictionaries, each containing the 'name' of the image and the 'image' as a base64 encoded string.
        server_address (str): The address of the ComfyUI server.

    Returns:
        list: A list of responses from the server for each image upload.
    """
    if not images:
        return {"status": "success", "message": "No images to upload", "details": []}

    responses = []
    upload_errors = []

    print(f"runpod-worker-comfy - image(s) upload")

    for image in images:
        name = image["name"]
        image_data = image["image"]
        blob = base64.b64decode(image_data)

        # Prepare the form data
        files = {
            "image": (name, BytesIO(blob), "image/png"),
            "overwrite": (None, "true"),
        }

        # POST request to upload the image
        response = requests.post(f"http://{COMFY_HOST}/upload/image", files=files)
        if response.status_code != 200:
            upload_errors.append(f"Error uploading {name}: {response.text}")
        else:
            responses.append(f"Successfully uploaded {name}")

    if upload_errors:
        print(f"runpod-worker-comfy - image(s) upload with errors")
        return {
            "status": "error",
            "message": "Some images failed to upload",
            "details": upload_errors,
        }

    print(f"runpod-worker-comfy - image(s) upload complete")
    return {
        "status": "success",
        "message": "All images uploaded successfully",
        "details": responses,
    }


def queue_workflow(workflow):
    """
    Queue a workflow to be processed by ComfyUI

    Args:
        workflow (dict): A dictionary containing the workflow to be processed

    Returns:
        dict: The JSON response from ComfyUI after processing the workflow
    """

    # The top level element "prompt" is required by ComfyUI
    data = json.dumps({"prompt": workflow}).encode("utf-8")

    req = urllib.request.Request(f"http://{COMFY_HOST}/prompt", data=data)
    return json.loads(urllib.request.urlopen(req).read())


def get_history(prompt_id):
    """
    Retrieve the history of a given prompt using its ID

    Args:
        prompt_id (str): The ID of the prompt whose history is to be retrieved

    Returns:
        dict: The history of the prompt, containing all the processing steps and results
    """
    with urllib.request.urlopen(f"http://{COMFY_HOST}/history/{prompt_id}") as response:
        return json.loads(response.read())


def base64_encode(img_path):
    """
    Returns base64 encoded image.

    Args:
        img_path (str): The path to the image

    Returns:
        str: The base64 encoded image
    """
    with open(img_path, "rb") as image_file:
        encoded_string = base64.b64encode(image_file.read()).decode("utf-8")
        return f"{encoded_string}"


def upload_to_azure_blob(job_id, local_image_path):
    """
    Uploads an image to Azure Blob Storage and returns the URL.

    Args:
        job_id (str): The unique identifier for the job.
        local_image_path (str): The path to the local image file.

    Returns:
        str: URL to the uploaded image in Azure Blob Storage.
    """
    try:
        # Get connection details from environment variables
        connection_string = os.environ.get("AZURE_STORAGE_CONNECTION_STRING")
        container_name = os.environ.get("AZURE_STORAGE_CONTAINER_NAME", "comfyui-images")
        
        # Create a unique name for the blob using job_id and file name
        file_name = os.path.basename(local_image_path)
        blob_name = f"{job_id}/{file_name}"

        # Create the BlobServiceClient object
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        
        # Get container client and create container if it doesn't exist
        container_client = blob_service_client.get_container_client(container_name)
        if not container_client.exists():
            container_client.create_container()
        
        # Create a blob client
        blob_client = blob_service_client.get_blob_client(
            container=container_name, 
            blob=blob_name
        )
        
        # Upload the file
        with open(local_image_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
        
        # Return the URL to the blob
        return blob_client.url
    
    except Exception as e:
        print(f"runpod-worker-comfy - Error uploading to Azure Blob Storage: {str(e)}")
        # Return None to indicate failure
        return None

def process_output_images(outputs, job_id):
    """
    This function takes the "outputs" from image generation and the job ID,
    then determines the correct way to return the images, either as direct URLs
    to an AWS S3 bucket, Azure Blob Storage, or as base64 encoded strings, 
    depending on the environment configuration.

    Args:
        outputs (dict): A dictionary containing the outputs from image generation,
                        typically includes node IDs and their respective output data.
        job_id (str): The unique identifier for the job.

    Returns:
        dict: A dictionary with the status ('success' or 'error') and the message,
              which is a list of dictionaries containing node_id, imageType ('url' or 'base64'),
              and the image data. In case of error, the message contains an error description.

    The function works as follows:
    - It first determines the output path for the images from an environment variable,
      defaulting to "/comfyui/output" if not set.
    - It then iterates through the outputs to find the filenames of the generated images.
    - For each image found, it checks if it exists in the output folder.
    - If the image exists, it checks if cloud storage is configured.
    - If Azure Blob Storage is preferred and configured, it uploads the image to Azure and adds the URL to the results.
    - If AWS S3 is configured, it uploads the image to the bucket and adds the URL to the results.
    - If no cloud storage is configured, it encodes the image in base64 and adds the string to the results.
    - If any image file does not exist in the output folder, it adds an error for that specific image.
    - Returns a list of all processed images with their node_id and image data.
    """

    # The path where ComfyUI stores the generated images
    COMFY_OUTPUT_PATH = os.environ.get("COMFY_OUTPUT_PATH", "/comfyui/output")
    
    # List to collect all image results
    image_results = []
    errors = []

    print(f"runpod-worker-comfy - image generation is done")

    # Process each node and its images
    for node_id, node_output in outputs.items():
        if "images" in node_output:
            for image in node_output["images"]:
                # Construct the image path
                image_path = os.path.join(image["subfolder"], image["filename"])
                local_image_path = f"{COMFY_OUTPUT_PATH}/{image_path}"
                
                print(f"runpod-worker-comfy - processing: {local_image_path}")
                
                # Check if the image file exists
                if os.path.exists(local_image_path):
                    # Get the preferred image return method from environment variable
                    # Possible values: "azure", "s3", "base64" (default)
                    image_return_method = os.environ.get("IMAGE_RETURN_METHOD", "base64").lower()
                    
                    if image_return_method == "azure" and os.environ.get("AZURE_STORAGE_CONNECTION_STRING"):
                        # Upload to Azure Blob Storage
                        image_data = upload_to_azure_blob(job_id, local_image_path)
                        if image_data:
                            image_type = "url"
                            print(f"runpod-worker-comfy - image from node {node_id} uploaded to Azure Blob Storage")
                        else:
                            # Fallback if Azure upload fails
                            if os.environ.get("BUCKET_ENDPOINT_URL", False):
                                image_data = rp_upload.upload_image(job_id, local_image_path)
                                image_type = "url"
                                print(f"runpod-worker-comfy - Azure upload failed, image from node {node_id} falling back to AWS S3")
                            else:
                                image_data = base64_encode(local_image_path)
                                image_type = "base64"
                                print(f"runpod-worker-comfy - Azure upload failed, image from node {node_id} falling back to base64")
                    elif image_return_method == "s3" and os.environ.get("BUCKET_ENDPOINT_URL", False):
                        # Upload to AWS S3
                        image_data = rp_upload.upload_image(job_id, local_image_path)
                        image_type = "url"
                        print(f"runpod-worker-comfy - image from node {node_id} uploaded to AWS S3")
                    elif image_return_method in ["azure", "s3"]:
                        # User requested cloud storage but it's not configured, fall back to base64
                        image_data = base64_encode(local_image_path)
                        image_type = "base64"
                        print(f"runpod-worker-comfy - {image_return_method} was requested but not configured, image from node {node_id} falling back to base64")
                    else:
                        # Use base64 (default)
                        image_data = base64_encode(local_image_path)
                        image_type = "base64"
                        print(f"runpod-worker-comfy - image from node {node_id} converted to base64")
                    
                    # Add this image to our results
                    image_results.append({
                        "node_id": node_id,
                        "imageType": image_type,
                        "image": image_data
                    })
                else:
                    error_msg = f"Image does not exist in the specified output folder: {local_image_path}"
                    print(f"runpod-worker-comfy - {error_msg}")
                    errors.append({
                        "node_id": node_id,
                        "error": error_msg
                    })

    # Return the results
    if image_results:
        return {
            "status": "success",
            "message": image_results,  # Keep the "message" field for backward compatibility
            "errors": errors if errors else []
        }
    else:
        return {
            "status": "error",
            "message": "No images were successfully generated or found",
            "errors": errors
        }


def handler(job):
    """
    The main function that handles a job of generating images.

    This function validates the input, sends a prompt to ComfyUI for processing,
    polls ComfyUI for result, and retrieves generated images.

    Args:
        job (dict): A dictionary containing job details and input parameters.

    Returns:
        dict: A dictionary containing either an error message or a success status with a message field
              that contains a list of generated images. Each image is represented as a dictionary with 
              node_id, imageType, and image data (either URL or base64).
    """
    job_input = job["input"]

    # Make sure that the input is valid
    validated_data, error_message = validate_input(job_input)
    if error_message:
        return {"error": error_message}

    # Extract validated data
    workflow = validated_data["workflow"]
    images = validated_data.get("images")

    # Make sure that the ComfyUI API is available
    check_server(
        f"http://{COMFY_HOST}",
        COMFY_API_AVAILABLE_MAX_RETRIES,
        COMFY_API_AVAILABLE_INTERVAL_MS,
    )

    # Upload images if they exist
    upload_result = upload_images(images)

    if upload_result["status"] == "error":
        return upload_result

    # Queue the workflow
    try:
        queued_workflow = queue_workflow(workflow)
        prompt_id = queued_workflow["prompt_id"]
        print(f"runpod-worker-comfy - queued workflow with ID {prompt_id}")
    except Exception as e:
        return {"error": f"Error queuing workflow: {str(e)}"}

    # Poll for completion
    print(f"runpod-worker-comfy - wait until image generation is complete")
    retries = 0
    try:
        while retries < COMFY_POLLING_MAX_RETRIES:
            history = get_history(prompt_id)

            # Exit the loop if we have found the history
            if prompt_id in history and history[prompt_id].get("outputs"):
                break
            else:
                # Wait before trying again
                time.sleep(COMFY_POLLING_INTERVAL_MS / 1000)
                retries += 1
        else:
            return {"error": "Max retries reached while waiting for image generation"}
    except Exception as e:
        return {"error": f"Error waiting for image generation: {str(e)}"}

    # Get the generated images and return them as URLs in an AWS bucket or as base64
    images_result = process_output_images(history[prompt_id].get("outputs"), job["id"])

    # Add refresh_worker flag to the result
    result = {**images_result, "refresh_worker": REFRESH_WORKER}

    return result


# Start the handler only if this script is run directly
if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})