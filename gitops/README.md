# GitOps and CI/CD with GitHub Actions & AWS

A comprehensive guide to implementing GitOps practices, CI/CD pipelines, and deploying Docker containers to AWS ECS and Fargate using GitHub Actions.

## 📚 Course Structure

### Lecture Notes
1. **[GitHub Actions Introduction](notes/01-github-actions-introduction.md)** - Learn the fundamentals of GitHub Actions, workflows, and automation
2. **[AWS ECS and Fargate](notes/02-aws-ecs-fargate.md)** - Understanding container orchestration with ECS and serverless containers with Fargate
3. **[CI/CD Pipeline Basics](notes/03-cicd-pipeline-basics.md)** - Core concepts of continuous integration and deployment
4. **[Docker to ECS Deployment](notes/04-docker-to-ecs.md)** - Complete guide to deploying Docker containers to AWS ECS

### Exercises
1. **[First GitHub Action](exercises/01-first-github-action.md)** - Create your first workflow and understand GitHub Actions basics
2. **[Docker Build and Push](exercises/02-docker-build-push.md)** - Automate Docker image building and pushing to ECR
3. **[Deploy to ECS](exercises/03-deploy-to-ecs.md)** - Complete CI/CD pipeline deploying to AWS ECS/Fargate

### Examples
- **simple-pipeline/** - Basic GitHub Actions workflow examples
- **docker-ecs/** - Docker containerization and ECS deployment
- **full-cicd/** - Complete end-to-end CI/CD pipeline with testing and deployment

## 🎯 Learning Objectives

By the end of this course, you will be able to:
- ✅ Create and manage GitHub Actions workflows
- ✅ Build Docker images automatically in CI/CD pipelines
- ✅ Push Docker images to Amazon ECR (Elastic Container Registry)
- ✅ Deploy containerized applications to AWS ECS
- ✅ Understand the difference between ECS EC2 and Fargate launch types
- ✅ Implement automated testing in CI/CD pipelines
- ✅ Manage secrets and environment variables securely
- ✅ Set up blue/green deployments
- ✅ Monitor and troubleshoot deployments

## 📋 Prerequisites

Before starting this course, you should have:
- Completed the Docker lectures (docker-lectures/)
- Basic understanding of Git and GitHub
- AWS account with appropriate permissions
- Docker installed on your local machine
- AWS CLI installed and configured
- Basic knowledge of YAML syntax

## 🚀 Getting Started

1. **Review Docker Concepts**: Make sure you're comfortable with Docker basics from the previous lectures
2. **Set Up AWS Account**: Ensure you have an AWS account with ECS and ECR permissions
3. **Configure GitHub**: You'll need a GitHub account and a repository to practice with
4. **Install Prerequisites**:
   ```bash
   # Verify Docker
   docker --version
   
   # Verify AWS CLI
   aws --version
   
   # Configure AWS credentials
   aws configure
   ```

## 🛠️ Tools and Technologies Covered

- **GitHub Actions** - CI/CD automation platform
- **Amazon ECS** - Container orchestration service
- **AWS Fargate** - Serverless compute for containers
- **Amazon ECR** - Container registry
- **Docker** - Container platform
- **AWS CLI** - Command-line interface for AWS
- **Terraform** (optional) - Infrastructure as Code

## 📖 Recommended Learning Path

1. Start with the GitHub Actions introduction
2. Set up your first workflow (Exercise 1)
3. Learn about AWS ECS and Fargate architecture
4. Practice Docker build and push automation (Exercise 2)
5. Study CI/CD pipeline concepts
6. Complete the full ECS deployment (Exercise 3)
7. Explore advanced examples

## 🔗 Related Resources

- [Docker Lectures](../docker-lectures/) - Foundation for container concepts
- [Terraform Tutorial](../terraform-tutorial/) - Infrastructure as Code for AWS resources
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/fargate/)

## 💡 Best Practices

- Always use secrets for sensitive data
- Tag your Docker images properly
- Use multi-stage builds for smaller images
- Implement proper error handling in workflows
- Monitor your deployments
- Use infrastructure as code when possible
- Implement proper rollback strategies

## 📝 Notes

- All examples assume you have proper AWS permissions
- Some services may incur AWS charges
- Always clean up resources after practicing
- Use IAM roles with least privilege principle

## 🤝 Contributing

Feel free to add more examples, improve documentation, or suggest better practices!

---

**Next Steps**: Start with [GitHub Actions Introduction](notes/01-github-actions-introduction.md)

