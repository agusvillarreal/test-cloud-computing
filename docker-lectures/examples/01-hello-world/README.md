# Hello World Docker Example

This is a simple Docker example that demonstrates basic Docker concepts.

## Files

- `Dockerfile` - Contains instructions to build the Docker image
- `README.md` - This documentation file

## How to Run

1. Navigate to the example directory:
   ```bash
   cd docker-lectures/examples/01-hello-world
   ```

2. Build the Docker image:
   ```bash
   docker build -t hello-world .
   ```

3. Run the container:
   ```bash
   docker run hello-world
   ```

## Expected Output

```
Hello, Docker World!
```

## What This Example Demonstrates

- Basic Dockerfile structure
- Using Alpine Linux as base image
- Setting working directory
- Creating and executing scripts
- Using CMD instruction

## Key Concepts

- **FROM**: Specifies the base image (Alpine Linux)
- **WORKDIR**: Sets the working directory inside the container
- **RUN**: Executes commands during image build
- **CMD**: Defines the default command to run when container starts
