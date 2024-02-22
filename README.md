# RadosGW Testing Container

This container provides an easy way to test clients with the RadosGW.
It's designed not to persist any data,
utilizing the Ceph OSD with Memstore as a backend.

## Dockerfile Details

1. Updates and installs necessary dependencies for Ceph installation.
2. Fetches the Ceph repository key and adds the repository for Ceph.
3. Installs Ceph and RadosGW packages.
4. Cleans up the container after installations to reduce its footprint.

## Usage

### Building the Container

You can build the container using the provided Dockerfile. Run the following command:

```bash
podman build -t radosgw .
```

### Running the Container (basic)

```bash
podman run \
    -p 7480:7480 \
    -p 8080:8080 \
    -e MAIN="none" \
    -e ACCESS_KEY="radosgwadmin" \
    -e SECRET_KEY="radosgwadmin" \
    -ti radosgw
```

this will start a cephcluster with a radosgw set to defaults

### Running the Container in multiside-mode

The multiside mode will make use of the internal DNS in podman and will need additional aliases for the containers.
Hostnames need to be set like `zone [a-z]` `cluster [0-9]` - `name [0-9a-z]` 

The Hostname will be splitt and reused for the radosgw configuration:

| variable  | hostname-part                | example |
|-----------|------------------------------|---------|
| REALM     | `zone [a-z]`                 | dev     |
| ZONEGROUP | `zone [a-z]`                 | dev     |
| ZONE      | `zone [a-z]` `cluster [0-9]` | dev1    |

* create a netwwork
```bash
podman network create local
```

* start the main-zone radosgw container
```bash
podman run \
    --hostname dev1-rgw1.dev.s3.localhost \
    --network-alias=dev1.dev.s3.localhost \
    --network-alias=dev.s3.localhost \
    --network=local \
    --ip 10.89.0.20 \
    -p7480:7480 \
    -p8080:8080 \
    -e MAIN=yes \
    -e ACCESS_KEY="radosgwadmin" \
    -e SECRET_KEY="radosgwadmin" \
    -e MGR_USERNAME="admin" \
    -e MGR_PASSWORD="admin" \
    -ti radosgw
```

* start the sub-zone radosgw container
```bash
podman run \
    --hostname dev2-rgw1.dev.s3.localhost \
    --network-alias=dev2.dev.s3.localhost \
    --network=local \
    --ip 10.89.0.21 \
    -p7481:7480 \
    -p8081:8080 \
    -e MAIN=no \
    -e ACCESS_KEY="radosgwadmin" \
    -e SECRET_KEY="radosgwadmin" \
    -e MGR_USERNAME="admin" \
    -e MGR_PASSWORD="admin" \
    -ti radosgw
```


## Environment Variables

| Name         | Usage                                         |
|--------------|-----------------------------------------------|
| MAIN         | Is zongroup-master (yes/no), set to "none" by default (no multi-site setup). |
| ACCESS_KEY   | Set to "radosgwadmin" by default.             |
| SECRET_KEY   | Set to "radosgwadmin" by default.             |
| MGR_USERNAME | Set zo "admin" by default.                    |
| MGR_PASSWORD | Set to radosgwadmin" by default.              |

## Exposed Ports

| Port | Proto | Usage            |
|------|-------|------------------|
| 7480 | TCP   | Ceph-RadosGW API | 
| 8080 | TCP   | Ceph-Dashboard   | 

## Entrypoint

The entrypoint script creates a new ceph-cluster with a radosgw expsing the s3 API. It performs the following key tasks:

1. Ceph Configuration File Generation: Generates the ceph.conf file with essential configurations for Ceph.
2. Mon (Monitor) Initialization: Creates monitor keys and initializes the monitor with associated settings.
3. Manager Creation: Sets up Ceph manager configurations.
4. OSD (Object Storage Daemon) Creation: Creates OSD and initializes its data directory.
5. RadosGW (RADOS Gateway) Configuration: Sets up RADOS Gateway and generates necessary keys.
6. S3 Admin Creation: Creates an S3 admin user.
7. Foreground Logging: Continuously logs Ceph-related output to monitor activity.

## Example usage

These examples are performed using the MinIO Client (mc) but any other s3 clients will work, too.

* Set up an alias for MinIO to interact with the RADOS Gateway
```bash
mc alias set test http://127.0.0.1:7480 radosgwadmin radosgwadmin --api "s3v4" --path "on"
```
* Create a bucket named "my-bucket"
```bash
mc mb test/my-bucket
```
* List all buckets
```bash
mc ls test
```
* Upload a file named "example.txt" to the "my-bucket" bucket
```bash
mc cp example.txt test/my-bucket/example.txt
```
* Download the "example.txt" file from the "my-bucket" bucket
```bash
mc cp test/my-bucket/example.txt ./downloaded-example.txt
```
* Remove the "example.txt" file from the "my-bucket" bucket
```bash
mc rm test/my-bucket/example.txt
```
* Remove the "my-bucket" bucket
```bash
mc rb --force test/my-bucket
```
