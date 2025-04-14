# 1.0.0 (2025-04-14)


### Bug Fixes

* added missing start command ([9a7ffdb](https://github.com/kimara-ai/runpod-worker-comfy/commit/9a7ffdb078d2f75194c86ed0b8c2d027592e52c3))
* check_server default values for delay and check-interval ([4945a9d](https://github.com/kimara-ai/runpod-worker-comfy/commit/4945a9d65b55aae9117591c8d64f9882d200478e))
* convert environment variables to int ([#70](https://github.com/kimara-ai/runpod-worker-comfy/issues/70)) ([7ab3d2a](https://github.com/kimara-ai/runpod-worker-comfy/commit/7ab3d2a234325c2a502002ea7bdee7df3e0c8dfe))
* create directories which are required to run ComfyUI ([#58](https://github.com/kimara-ai/runpod-worker-comfy/issues/58)) ([6edf62b](https://github.com/kimara-ai/runpod-worker-comfy/commit/6edf62b0f4cd99dba5c22dd76f51c886f57a28ed))
* don’t persist credentials ([1546420](https://github.com/kimara-ai/runpod-worker-comfy/commit/15464201b24de0746fe365e7635540330887a393))
* don't run ntpdate as this is not working in GitHub Actions ([2f7bd3f](https://github.com/kimara-ai/runpod-worker-comfy/commit/2f7bd3f71f24dd3b6ecc56f3a4c27bbc2d140eca))
* fix unit tests ([211e23e](https://github.com/kimara-ai/runpod-worker-comfy/commit/211e23eda7e154381d5e9c71d6e3699e66d670ee))
* got rid of syntax error ([c04de4d](https://github.com/kimara-ai/runpod-worker-comfy/commit/c04de4dea93dbe586a9a887e04907b33597ff73e))
* images in subfolders are not working, fixes [#12](https://github.com/kimara-ai/runpod-worker-comfy/issues/12) ([37480c2](https://github.com/kimara-ai/runpod-worker-comfy/commit/37480c2d217698f799f6388ff311b9f8c6c38804))
* path should be "loras" and not "lora" ([8e579f6](https://github.com/kimara-ai/runpod-worker-comfy/commit/8e579f63e18851b0be67bff7a42a8e8a46223f2b))
* removed xl_more_art-full_v1 because civitai requires login now ([2e8e638](https://github.com/kimara-ai/runpod-worker-comfy/commit/2e8e63801a7672e4923eaad0c18a4b3e2c14d79c))
* return the output of "process_output_image" and access jobId correctly ([#11](https://github.com/kimara-ai/runpod-worker-comfy/issues/11)) ([dc655ea](https://github.com/kimara-ai/runpod-worker-comfy/commit/dc655ea0dd0b294703f52f6017ce095c3b411527))
* runner workflow images ([65fdca1](https://github.com/kimara-ai/runpod-worker-comfy/commit/65fdca13531130f981fa3ec1e3389e70fe8dd56b))
* **semantic-release:** added .releaserc ([#21](https://github.com/kimara-ai/runpod-worker-comfy/issues/21)) ([12b763d](https://github.com/kimara-ai/runpod-worker-comfy/commit/12b763d8703ce07331a16d4013975f9edc4be3ff))
* set correct variables for release actions ([acdf35d](https://github.com/kimara-ai/runpod-worker-comfy/commit/acdf35d9814c9b36aadf5651bd8b8456dd45fce2))
* start the container in all cases ([413707b](https://github.com/kimara-ai/runpod-worker-comfy/commit/413707bf130eb736afd682adac8b37fa64a5c9a4))
* update the version inside of semanticrelease ([d93e991](https://github.com/kimara-ai/runpod-worker-comfy/commit/d93e991b82251d62500e20c367a087d22d58b20a))
* updated path to "comfyui" ([37f66d0](https://github.com/kimara-ai/runpod-worker-comfy/commit/37f66d04b8c98810714ffbc761412f3fcdb1d861))
* use custom GITHUB_TOKEN to bypass branch protection ([9b6468a](https://github.com/kimara-ai/runpod-worker-comfy/commit/9b6468a40b8a476d7812423ff6fe7b73f5f91f1d))


### Features

* added default ComfyUI workflow ([fa6c385](https://github.com/kimara-ai/runpod-worker-comfy/commit/fa6c385e0dc9487655b42772bb6f3a5f5218864e))
* added FLUX.1 schnell & dev ([9170191](https://github.com/kimara-ai/runpod-worker-comfy/commit/9170191eccb65de2f17009f68952a18fc008fa6a))
* added runpod as local dependency ([9deae9f](https://github.com/kimara-ai/runpod-worker-comfy/commit/9deae9f5ec723b93540e6e2deac04b8650cf872a))
* added sensible defaults and default platform ([3f5162a](https://github.com/kimara-ai/runpod-worker-comfy/commit/3f5162af85ee7d0002ad65a7e324c3850e00a229))
* added support for hub ([c8dd49c](https://github.com/kimara-ai/runpod-worker-comfy/commit/c8dd49cc2d8c23d58b48b1823bdecc3267f9accd))
* added unit tests for everthing, refactored the code to make it better testable, added test images ([a7492ec](https://github.com/kimara-ai/runpod-worker-comfy/commit/a7492ec8f289fc64b8e54c319f47804c0a15ae54))
* added xl_more_art-full_v1, improved comments ([9aea8ab](https://github.com/kimara-ai/runpod-worker-comfy/commit/9aea8abe1375f3d48aa9742c444b5242111e3121))
* automatically update latest version ([7d846e8](https://github.com/kimara-ai/runpod-worker-comfy/commit/7d846e8ca3edcea869db3e680f0b423b8a98cc4c))
* base64 image output ([#8](https://github.com/kimara-ai/runpod-worker-comfy/issues/8)) ([76bf0b1](https://github.com/kimara-ai/runpod-worker-comfy/commit/76bf0b166b992a208c53f5cb98bd20a7e3c7f933))
* example on how to configure the .env ([4ed5296](https://github.com/kimara-ai/runpod-worker-comfy/commit/4ed529601394e8a105d171ab1274737392da7df5))
* hard fork from blib-la/runpod-worker-comfy ([9fb8cd8](https://github.com/kimara-ai/runpod-worker-comfy/commit/9fb8cd82096994cedbbf3a7027b5f3c7de5e94f4))
* image-input, renamed "prompt" to "workflow", added "REFRESH_WORKER" ([#14](https://github.com/kimara-ai/runpod-worker-comfy/issues/14)) ([5f5e390](https://github.com/kimara-ai/runpod-worker-comfy/commit/5f5e390dfda9d3ef8ce9b5578aade1bee600bf5c))
* logs should be written to stdout so that we can see them inside the worker ([fc731ff](https://github.com/kimara-ai/runpod-worker-comfy/commit/fc731fffcd79af67cf6fcdf6a6d3df6b8e30c7b5))
* network-volume; execution time config; skip default images; access ComfyUI via web ([#35](https://github.com/kimara-ai/runpod-worker-comfy/issues/35)) ([070cde5](https://github.com/kimara-ai/runpod-worker-comfy/commit/070cde5460203e24e3fbf68c4ff6c9a9b7910f3f)), closes [#16](https://github.com/kimara-ai/runpod-worker-comfy/issues/16)
* run the worker locally ([#19](https://github.com/kimara-ai/runpod-worker-comfy/issues/19)) ([34eb32b](https://github.com/kimara-ai/runpod-worker-comfy/commit/34eb32b72455e6e628849e50405ed172d846d2d9))
* simplified and added compatibility with Windows ([9f41231](https://github.com/kimara-ai/runpod-worker-comfy/commit/9f412316a743f0539981b408c1ccd0692cff5c82))
* simplified input ([35c2341](https://github.com/kimara-ai/runpod-worker-comfy/commit/35c2341deca346d4e6df82c36e101b7495f3fc03))
* simplified input to just have "prompt", removed unused code ([0c3ccda](https://github.com/kimara-ai/runpod-worker-comfy/commit/0c3ccda9c5c8cdc56eae829bb358ceb532b36371))
* support sd3 ([#46](https://github.com/kimara-ai/runpod-worker-comfy/issues/46)) ([dde69d6](https://github.com/kimara-ai/runpod-worker-comfy/commit/dde69d6ca75eb7e4c5f01fd17e6da5b62f8a401f))
* update comfyui to 0.3.26 ([ac0269e](https://github.com/kimara-ai/runpod-worker-comfy/commit/ac0269e683a0bcba43fafad40d4b56f51cad2588))
* updated path to "comfyui", added "ntpdate" to have the time of the container in sync with AWS ([2fda578](https://github.com/kimara-ai/runpod-worker-comfy/commit/2fda578d62460275abec11d6b2fbe5123d621d5f))
* use local ".env" to load env variables, mount "comfyui/output" to localhost so that people can see the generated images ([aa645a2](https://github.com/kimara-ai/runpod-worker-comfy/commit/aa645a233cd6951d296d68f7ddcf41b14b3f4cf9))
* use models from huggingface, not from local folder ([b1af369](https://github.com/kimara-ai/runpod-worker-comfy/commit/b1af369bb577c0aaba8875d8b2076e1888356929))
* wait until server is ready, wait until image generation is done, upload to s3 ([ecfec13](https://github.com/kimara-ai/runpod-worker-comfy/commit/ecfec1349da0d04ea5f21c82d8903e1a5bd3c923))


### BREAKING CHANGES

* This is a complete hard fork from the original project.
- Reset version to 1.0.0
- Updated all Docker image references to kimaraai/runpod-worker-comfy
- Updated acknowledgments and removed links to original repo issues
- Cleaned up the changelog to start fresh
* we have 3 different images now instead of just one: base, sdxl and sd3

* ci: use branch name for creating dev releases

* ci: replace "/" with "-" to have a valid tag name

* ci: correctly handle the tag  name

* ci: build an image that contains sd3 using docker bake

* ci: use "set" instead of "args"

* ci: use "env" instead of "set"

* ci: use variables instead of args

* ci: set variables directly for the targets

* ci: write the secrets into the GITHUB_ENV

* ci: handle env variables correctly

* ci: use env variables from GitHub Variables

* ci: added back to env

* ci: print out env

* ci: adding the vars directly into the workflow

* ci: example workflow for sd3

* ci: renamed DOCKERHUB_REPO to DOCKERHUB_REPOSITORY

* ci: removed quotes for DOCKERHUB_REPOSITORY

* ci: only use DOCKERHUB_REPO in bake

* ci: added vars into sd3 target

* ci: added direct target

* ci: back to basics

* ci: multi-stage build to not expose the HUGGINGFACE_ACCESS_TOKEN

* ci: write everything into GITHUB_ENV again

* ci: use correct name for final stage

* ci: use correct runner

* fix: make sure to use the latest versions of all packages

* ci: simplified variables for all targets

* docs: added 3 images, updated build your own image

* docs: updated TOC

* ci: updated name

* ci: use docker bake to publish 3 images instead of just 1

# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 (2025-04-13)

Initial release as an independent project.

### Features
- Azure Blob Storage support
- Multi-image output support
- Environment variable to control image output method (azure, s3, or base64)

### Notes
This project was originally forked from [blib-la/runpod-worker-comfy](https://github.com/blib-la/runpod-worker-comfy) but is now independently maintained.
The version numbering has been reset to 1.0.0 to reflect the new project history.
