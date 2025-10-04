# Docker Usage for pia-wg-config

## Building the Container

```bash
# Build for current architecture
make docker-build

# Build for multiple architectures (requires Docker buildx)
make docker-build-multiarch

# Manual build
docker build -t pia-wg-config -f docker/Dockerfile .
```

## Usage

The container runs the `pia-wg-config` binary directly with command-line arguments (no environment variables).

### Command Line Format

```bash
docker run --rm pia-wg-config [OPTIONS] USERNAME PASSWORD
```

**Options:**
- `-r, --region REGION` - Region to connect to (default: "us_california")
- `-o, --outfile FILE` - Output file path (default: stdout)
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**Special Commands:**
- `regions` - List all available regions

## Usage Examples

### Basic Usage

Generate config for default region (us_california):

```bash
docker run --rm pia-wg-config:latest myusername mypassword
```

### Specify a Region

Generate config for UK London servers:

```bash
docker run --rm pia-wg-config:latest -r uk_london myusername mypassword
```

### Save Config to Host File

Mount a volume and save the config to your host:

```bash
mkdir -p ./configs
docker run --rm \
  -v $(pwd)/configs:/output \
  pia-wg-config:latest \
  -r de_frankfurt -o /output/germany.conf \
  myusername mypassword
```

### List Available Regions

```bash
docker run --rm pia-wg-config:latest regions
```

### Enable Verbose Output

```bash
docker run --rm pia-wg-config:latest -v -r japan myusername mypassword
```

### Using Makefile (Recommended)

```bash
# Basic usage
make docker-run PIA_USERNAME=myuser PIA_PASSWORD=mypass

# With specific region  
make docker-run PIA_USERNAME=myuser PIA_PASSWORD=mypass PIA_REGION=uk_london

# List regions
make docker-run-regions
```

## Docker Compose Example

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  pia-wg-config:
    build:
      context: .
      dockerfile: docker/Dockerfile
    command: ["-r", "uk_london", "-o", "/output/wg.conf", "${PIA_USERNAME}", "${PIA_PASSWORD}"]
    volumes:
      - ./configs:/output
    environment:
      - PIA_USERNAME=${PIA_USERNAME}
      - PIA_PASSWORD=${PIA_PASSWORD}
```

Create a `.env` file:

```bash
PIA_USERNAME=your_username
PIA_PASSWORD=your_password
```

Run with:

```bash
docker-compose up --rm pia-wg-config
```

## Kubernetes Example

Create a Kubernetes Job:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pia-wg-config
spec:
  template:
    spec:
      containers:
      - name: pia-wg-config
        image: pia-wg-config:latest
        args: ["-r", "uk_london", "-o", "/output/wg.conf", "$(PIA_USERNAME)", "$(PIA_PASSWORD)"]
        env:
        - name: PIA_USERNAME
          valueFrom:
            secretKeyRef:
              name: pia-credentials
              key: username
        - name: PIA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pia-credentials
              key: password
        volumeMounts:
        - name: config-storage
          mountPath: /output
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
      volumes:
      - name: config-storage
        persistentVolumeClaim:
          claimName: pia-config-pvc
      restartPolicy: OnFailure
```

Create the secret:

```bash
kubectl create secret generic pia-credentials \
  --from-literal=username=your_username \
  --from-literal=password=your_password
```

## Troubleshooting

### Permission Issues

If you encounter permission issues with mounted volumes, note that the container runs as UID 65532:

```bash
# Check ownership of output directory
ls -la ./configs

# Fix permissions if needed
sudo chown -R 65532:65532 ./configs
```

### Debug Mode

Run with verbose output to debug issues:

```bash
docker run --rm pia-wg-config:latest -v -r uk_london myusername mypassword
```

### Container Inspection

Since this is a distroless image, there's no shell available. For debugging:

```bash
# Check if the image works
docker run --rm pia-wg-config:latest --help

# List available regions
docker run --rm pia-wg-config:latest regions
```
