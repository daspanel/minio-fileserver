
# Usage


### Get
```shell
$ docker pull daspanel/minio-fileserver:latest
```

### Run
```shell
$ docker run -e DASPANEL_MASTER_EMAIL=my@email.com --name=my-minio-fileserver daspanel/minio-fileserver:latest
```

### Stop
```shell
$ docker stop my-minio-fileserver
```

### Update image
```shell
$ docker stop my-minio-fileserver
$ docker pull daspanel/minio-fileserver:latest
$ docker run -e DASPANEL_MASTER_EMAIL=my@email.com --name=my-minio-fileserver daspanel/minio-fileserver:latest
```

# Tips
