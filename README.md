# GitLab Fargate Runners
Knowledge document for Fargate GitLab runners CI

## General Info
This repo is documentation about our GitLab CI on AWS ECS system using Fargate tasks. Mainly following the [Official GitLab Fargate Guide](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/).

## Architecture
We use an EC2 instance that polls GitLab for pipeline requests, and schedules the ECS Fargate tasks. Each job in the pipeline will get scheduled into a different Fargate container, and the EC2 will coordinate between them.

## Dockerfile
Since our GitLab pipelines are based on alpine, we need to modify the [Dockerfile](./Dockerfile) mentioned in the official docs. We change the underlying image to alpine and use APK to install stuff.

## Entrypoint
In the dockerfile we specify an [Entrypoint script](./docker-entrypoint.sh), ours differs a bit from the guide again, due to different underlying OS, we need to add some alpine-specific commands to make sure the SSH server works correctly.

## Registration script
A little [Registration Script](./register_runners.py) utility was written to help register many tokens at once. It registers a group/project using the GitLab-runner binary and then uses string replace to correct the configuration file, as some changes are needed like mentioned in the official docs. You use the script just by executing it with a list of runner tokens as command line parameters. If you have a very large amount of tokens that do not fit within the CLI limit, you might need to modify the script or split the list into smaller chunks.

## Changes to the driver
We forked the official GitLab Fargate driver to add retries to the SSH execution in order to prevent errors. <br>
Our Fork: https://gitlab.com/ekronot2023/fargate <br>
Original Repo: https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate

## Setup
You should follow the official guide as mentioned at the start, here are some comments about the divergence from the original guide:

### 1. Create the runner image
Build the [Dockerfile](./Dockerfile) into an image, giving it an appropriate name. [Docs](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-1-prepare-a-container-image-for-the-aws-fargate-task)

### 2. Push into ECR
After your image is built, Go to AWS ECR (Elastic Container Registry), and select or create a new repo. Then click the 'View push commands' button and follow the instructions on how to authenticate and push your image to ECR. [Docs](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-2-push-the-container-image-to-a-registry)

### 3. Create an EC2 instance
Create an EC2 instance following the instructions on the [Docs](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-3-create-an-ec2-instance-for-gitlab-runner), including the IAM role, Security Group, and Key Pair (Unless you have one already).

### 4. Set up the EC2
Follow the instructions on the [Docs](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-4-install-and-configure-gitlab-runner-on-the-ec2-instance) to install the GitLab runner, up until the point of installing the Fargate driver. Here we diverge from the docs a little bit, we modified the driver to reconnect on SSH connection, to prevent some of the errors that we encountered.
In the EC2, install Go according to the [official instructions](https://go.dev/doc/install). Clone [our fork](https://gitlab.com/ekronot2023/fargate) of the driver. Inside the clone repo, run `go build ./cmd/fargate/`. Copy the resulting binary to `/opt/gitlab-runner/`.

### 5&6. Set up ECS
Follow the [5](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-4-install-and-configure-gitlab-runner-on-the-ec2-instance) and [6](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/#step-4-install-and-configure-gitlab-runner-on-the-ec2-instance) Docs to create and configure the ECS cluster with the Fargate task. Remember to input the ECR image we created earlier, and change the config from stage 4 to match the ECS cluster.