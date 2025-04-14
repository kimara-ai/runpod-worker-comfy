variable "DOCKERHUB_REPO" {
  default = "kimaraai"
}

variable "DOCKERHUB_IMG" {
  default = "runpod-worker-comfy"
}

variable "RELEASE_VERSION" {
  default = "latest"
}

variable "HUGGINGFACE_ACCESS_TOKEN" {
  default = ""
}

group "default" {
  targets = ["base", "sdxl"]
}

target "base" {
  context = "."
  dockerfile = "Dockerfile"
  target = "base"
  platforms = ["linux/amd64"]
  tags = ["${DOCKERHUB_REPO}/${DOCKERHUB_IMG}:${RELEASE_VERSION}-base"]
}

target "sdxl" {
  context = "."
  dockerfile = "Dockerfile"
  target = "final"
  args = {
    MODEL_TYPE = "sdxl"
  }
  tags = ["${DOCKERHUB_REPO}/${DOCKERHUB_IMG}:${RELEASE_VERSION}-sdxl"]
  inherits = ["base"]
}


