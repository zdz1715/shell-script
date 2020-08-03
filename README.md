# shell-script

脚本：

> [docker主机部署平滑重启](./devops/docker/local-smooth-upgrade.sh) 

使用方式：

参数：

| 参数 | 描述 | 是否必须 |
| :----: | :----: | :----: |
| DOCKER_WAREHOUSE | 镜像仓库 | 是 |
| DOCKER_TAG | 镜像tag | 是 |
| PROJECT_NAME | 项目名称 | 是 |
| ROOT_DIR | 构建信息存储路径，默认：`/srv/docker-flow` | 否 |
| NGINX_CONFIG_FILE | nginx配置文件，文件不存在则会生成，若存在，将会替换老容器ip，所以反向代理的时候必须要设置容器ip | 否 |
| NGINX_INI_PORT | nginx配置不存在创建的初始化端口，默认80 | 否 |
| CURRENT_CONTAINER_NAME | 若使用脚本前已经运行了容器，需要传入当前容器的名称，才能替换nginx里的容器ip，只是初次使用 | 否 |
| CURRENT_IMAGE | 使用该脚本前的镜像，只是初次使用 | 否 |


```shell script
    export url='https://github.com/zdz1715/shell-script/blob/master/devops/docker/local-smooth-upgrade.sh'
    export docker_tag=v1.0
    export docker_warehouse=registry.cn-hangzhou.aliyuncs.com/xx/xx
    DOCKER_WAREHOUSE=docker_warehouse DOCKER_TAG=docker_tag PROJECT_NAME=xx /bin/bash -c "$(curl -s $url)"
```
