# shell-script

## 脚本：

> [docker主机部署平滑重启](./devops/docker/local-smooth-upgrade.sh) 

### 使用方式：

| 参数 | 描述 | 是否必须 |
| :----: | :----: | :----: |
| DOCKER_WAREHOUSE | 镜像仓库 | 是 |
| DOCKER_TAG | 镜像tag | 是 |
| DOCKER_RUN_OPTIONS | docker 运行命令，默认只启动容器，没有任何选项 比如："-v project_path:var/www -p 80:80" | 否 |
| PROJECT_NAME | 项目名称 | 是 |
| ROOT_DIR | 构建信息存储路径，默认：`/srv/docker-flow` | 否 |
| NGINX_CONFIG_FILE | nginx配置文件，文件不存在则会生成，若存在，则会替换老容器ip| 否 |
| NGINX_INI_PORT | nginx配置初始化的端口，默认80 | 否 |
| CURRENT_CONTAINER_NAME | 若使用脚本前已经运行了容器，需要传入当前容器的名称，才能替换nginx里的容器ip | 否 |
| CURRENT_IMAGE | 若使用脚本前已经运行了容器，需要传入当前镜像的名称 | 否 |

#### 运行命令
```shell script
    export docker_tag=v1.0
    export docker_warehouse=registry.cn-hangzhou.aliyuncs.com/xx/xx
    DOCKER_WAREHOUSE=$docker_warehouse DOCKER_TAG=$docker_tag PROJECT_NAME=xx /bin/bash -c "$(curl -s  https://raw.githubusercontent.com/zdz1715/shell-script/master/devops/docker/local-smooth-upgrade.sh)"
```

#### nginx配置示例
```editorconfig
server {
    listen 80;

    server_name _;

    location / {
        proxy_pass http://172.168.0.4/;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
    location ~ /\.ht {
        deny all;
    }
}
```

`172.168.0.4` 为容器ip，直接反向代理容器内部端口，容器端口不要绑定到宿主机端口。此举可能会导致新容器端口冲突，启动失败

