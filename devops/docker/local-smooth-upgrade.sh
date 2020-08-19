#!/bin/bash

# 开始时间
START_TIME=$(date +'%Y-%m-%d %H:%M:%S')
START_SECONDS=$(date --date="$START_TIME" +%s)


docker_rm()
{
  log_command "docker rm -f $1"
  log_command "docker rmi $2"
  docker_logout
}

docker_login()
{
  if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PWD" ]; then
    DOCKER_USER=$(echo "$DOCKER_USER" | base64 -d)
    DOCKER_PWD=$(echo "$DOCKER_PWD" | base64 -d)

    bash -c "echo '$DOCKER_PWD' | docker login --username $DOCKER_USER --password-stdin $DOCKER_WAREHOUSE"
  fi
}

docker_logout()
{
  if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PWD" ]; then
      docker logout "$DOCKER_WAREHOUSE"
  fi
}

step()
{
  echo "# ========================================================= #"
  echo "# $1 "
  echo "# ========================================================= #"
}

log()
{
  echo "$1：$2"
}

log_error()
{
  log "[ERROR]" "$1"
}

log_info()
{
  log "[INFO]" "$1"
}

log_success()
{
  log "[SUCCESS]" "$1"
}

log_command()
{
  log "[COMMAND]" "$1"
  if [[ -z $2 ]]; then
    bash -c "$1"
  fi
}

if [[ -z "${DOCKER_WAREHOUSE}" ]] || [[ -z "${DOCKER_TAG}" ]]; then
  log_error "请设置镜像仓库和镜像tag"
  exit 1
fi

if [[ -z "${PROJECT_NAME}" ]]; then
  log_error "请设置项目名称"
  exit 1
fi
# 构建信息存储路径
if [[ -z "${ROOT_DIR}" ]]; then
  ROOT_DIR=/srv/docker-flow
fi


export IMAGE=${DOCKER_WAREHOUSE}:${DOCKER_TAG}
export CONTAINER_NAME=${PROJECT_NAME}_${DOCKER_TAG}
export LOCK_DIR=${ROOT_DIR}/.lock
export LOCK_IMAGE_FILE=${LOCK_DIR}/${PROJECT_NAME}_image.lock
export LOCK_CONTAINER_FILE=${LOCK_DIR}/${PROJECT_NAME}_container.lock



# 检测锁文件
if [[ -f "${LOCK_IMAGE_FILE}" ]]; then
  CURRENT_IMAGE=$(cat "${LOCK_IMAGE_FILE}")
  if [ "${IMAGE}" == "${CURRENT_IMAGE}" ]; then
    log_error "镜像已经是最新版"
    exit 1
  fi
fi

if [[ -f "${LOCK_CONTAINER_FILE}" ]]; then
  CURRENT_CONTAINER_NAME=$(cat "${LOCK_CONTAINER_FILE}")
  if [ "${CONTAINER_NAME}" == "${CURRENT_CONTAINER_NAME}" ]; then
    log_error "容器已经是最新版"
    exit 1
  fi
fi

step "初始化"
log_info "ROOT_DIR=${ROOT_DIR}"
log_info "DOCKER_WAREHOUSE=${DOCKER_WAREHOUSE}"
log_info "DOCKER_TAG=${DOCKER_TAG}"
log_info "PROJECT_NAME=${PROJECT_NAME}"
log_info "IMAGE=${IMAGE}"
log_info "CONTAINER_NAME=${CONTAINER_NAME}"
log_info "LOCK_DIR=${LOCK_DIR}"
log_info "LOCK_IMAGE_FILE=${LOCK_IMAGE_FILE}"
log_info "LOCK_CONTAINER_FILE=${LOCK_CONTAINER_FILE}"
log_info "CURRENT_IMAGE=${CURRENT_IMAGE}"
log_info "CURRENT_CONTAINER_NAME=${CURRENT_CONTAINER_NAME}"

if [[ ! -d "${ROOT_DIR}" ]]; then
  log_command "mkdir ${ROOT_DIR}"
fi

if [[ ! -d "${LOCK_DIR}" ]]; then
  log_command "mkdir ${LOCK_DIR}"
fi



step "拉取最新镜像"
# 登录docker
docker_login

if ! log_command "docker pull ${IMAGE}"; then
  log_error "镜像拉取失败"
  exit 1
fi


step "启动镜像"

DOCKER_RUN_COMMAND="docker run --name=${CONTAINER_NAME} -d ${IMAGE}"

if [[ -n "${DOCKER_RUN_OPTIONS}" ]]; then
  DOCKER_RUN_COMMAND="docker run --name=$CONTAINER_NAME ${DOCKER_RUN_OPTIONS} -d ${IMAGE}"
fi

if ! log_command "$DOCKER_RUN_COMMAND"; then
  log_error "镜像运行失败"
  exit 1
fi


step "获取容器ip"

log_command "APP_CONTAINER_IP=\$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CONTAINER_NAME})" 1

APP_CONTAINER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "${CONTAINER_NAME}")

if [[ -z "${APP_CONTAINER_IP}" ]]; then
	log_error "容器ip获取失败"
	docker_rm "${CONTAINER_NAME}" "${IMAGE}"
	exit 1
fi

log_info "APP_CONTAINER_IP=${APP_CONTAINER_IP}"

# 配置nginx
# 依赖于$app_docker_ip，需要这样配置
#  location / {
#        set $app_docker_ip 172.17.0.2;
#        proxy_pass http://$app_docker_ip;
#    }

if [[ -n "${NGINX_CONFIG_FILE}" ]]; then
  step "NGINX配置：${NGINX_CONFIG_FILE}"
  # 若是没有则生成配置文件
  if [[ ! -f ${NGINX_CONFIG_FILE} ]]; then
      if [[ -z ${NGINX_INI_PORT} ]]; then
        NGINX_INI_PORT=80
      fi

      log_command "tee $NGINX_CONFIG_FILE <<EOF
          server {
            listen $NGINX_INI_PORT;

            server_name _;

            location / {
                proxy_pass http://${APP_CONTAINER_IP}/;
            }

            location ~ /\.(?!well-known).* {
                deny all;
            }
            location ~ /\.ht {
                deny all;
            }
        }
EOF"
  else

    if [[ -z "${CURRENT_CONTAINER_NAME}" ]] || [[ -z "${CURRENT_IMAGE}" ]]; then
      log_error "获取不到CURRENT_CONTAINER_NAME、CURRENT_IMAGE变量，请手动传入"
      docker_rm "${CONTAINER_NAME}" "${IMAGE}"
      exit 1
    fi

    log_command "CURRENT_CONTAINER_IP=\$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CURRENT_CONTAINER_NAME})" 1
    CURRENT_CONTAINER_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "${CURRENT_CONTAINER_NAME}")

    log_info "CURRENT_CONTAINER_IP=${CURRENT_CONTAINER_IP}"

    if [[ -z "${CURRENT_CONTAINER_IP}" ]]; then
      log_error "获取不到当前容器运行的ip"
      docker_rm "${CONTAINER_NAME}" "${IMAGE}"
      exit 1
    fi

    log_command "sed -i \"s/${CURRENT_CONTAINER_IP}/${APP_CONTAINER_IP}/g\" ${NGINX_CONFIG_FILE}"

    log_command "cat $NGINX_CONFIG_FILE"
  fi



	# 检测nginx配置
  log_command "nginx -t"

  if ! nginx -t >/dev/null 2>&1; then
    # 删除容器
    docker_rm "${CONTAINER_NAME}" "${IMAGE}"
    exit 1
  fi

  # 重新载入nginx配置
  log_command "nginx -s reload"

fi

step "生成锁文件"

log_command "echo ${IMAGE} > ${LOCK_IMAGE_FILE}"
log_command "echo ${CONTAINER_NAME} > ${LOCK_CONTAINER_FILE}"




if [[ -n "${CURRENT_CONTAINER_NAME}" ]]; then
  step "删除旧容器"
  log_command "docker rm -f ${CURRENT_CONTAINER_NAME}"
fi

if [[ -n "${CURRENT_IMAGE}" ]]; then
  step "删除旧镜像"
  log_command "docker rmi ${CURRENT_IMAGE}"
fi

step "result"
docker_logout

END_TIME=$(date +'%Y-%m-%d %H:%M:%S')
END_SECONDS=$(date --date="$END_TIME" +%s)
log_success "执行成功：$((END_SECONDS-START_SECONDS))s"
