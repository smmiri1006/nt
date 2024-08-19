#!/bin/bash
# ntqq.sh

print_welcome() {
  clear
  echo "██╗     ███╗   ███╗██╗   ██╗███████╗    ██████╗ ██████╗ ███╗   ███╗"
  echo "██║     ████╗ ████║██║   ██║██╔════╝   ██╔════╝██╔═══██╗████╗ ████║"
  echo "██║     ██╔████╔██║██║   ██║███████╗   ██║     ██║   ██║██╔████╔██║"
  echo "██║     ██║╚██╔╝██║██║   ██║╚════██║   ██║     ██║   ██║██║╚██╔╝██║"
  echo "███████╗██║ ╚═╝ ██║╚██████╔╝███████║██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║"
  echo "╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝"
  echo "                落幕屋-https://lmu5.com"
  echo "欢迎使用本脚本，本脚本由落幕屋官网提供，脚本可能会有更新，"
  echo "建议去落幕屋官网时刻查看是否有最新的动态。"
  echo "如果遇到问题欢迎加QQ群:420035660"
  echo "本脚本适用于arm和amd架构的服务器和无界/autMan，请确认自己的架构是否支持。"
  echo "本脚本运行后会删除您设备上原来的相关NTQQ镜像和NTQQ容器，以便支持最新的镜像版本。"
  echo
  read -p "如您同意以上内容并继续，请按y，否则请按q退出: " choice

  case $choice in
    [Yy])
      ;;
    [Qq])
      echo "脚本已退出。"
      exit 0
      ;;
    *)
      echo "无效输入，脚本已退出。"
      exit 1
      ;;
  esac
}

is_number() {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "机器人QQ号必须纯数字！！！"
    return 1
  else
    return 0
  fi
}

update_config() {
  local file="$1"
  local ip="$2"
  local port="$3"
  local endpoint="$4"

  sed -i "s|\"ws://.*\"|\"ws://${ip}:${port}${endpoint}\"|" "$file"
  echo "配置文件已更新。"
}

print_welcome

read -p "请选择您要配置的平台类型 (输入1或2) 
1) 无界
2) autMan:" platform_choice

case "$platform_choice" in
  1)
    endpoint="/api/bot/qqws" # 无界
    ;;
  2)
    endpoint="/qq/receive" # autMan
    ;;
  *)
    echo "选择错误，脚本退出。"
    exit 1
    ;;
esac

if [[ $(docker images -q luomubiji/ntqq:latest) ]] || [[ $(docker ps -a -q -f name=^/NTQQ$) ]]; then
  read -p "提醒：当前存在luomubiji/ntqq:latest或者NTQQ容器，要不要删除(y/N): " remove_choice
  if [[ $remove_choice =~ ^[Yy]$ ]]; then
    docker rm -f NTQQ 2>/dev/null
    docker rmi luomubiji/ntqq:latest
  fi
fi

mkdir -p LLOneBot
cd LLOneBot
config_file_to_edit=""
config_files_found=$(ls config_*.json 2>/dev/null)

if [[ -n "$config_files_found" ]]; then
  echo "发现存在现有的配置文件："
  for file in $config_files_found; do
    echo "$file"
    read -p "这是您想要保留的配置文件吗？建议选择N删除！(y/N): " confirmation
    if [[ $confirmation =~ ^[Nn]$ ]]; then
      rm "$file"
      echo "已删除 $file。"
    fi
  done
fi

if [[ -z "$config_file_to_edit" ]]; then
  read -p "请输入机器人QQ号：" qq_number
  until is_number "$qq_number"; do
    read -p "QQ号必须是数字，请重新输入：" qq_number
  done

  read -p "请输入（无界/autMan）IP地址或者域名：" ip_addr
  read -p "请输入（无界/autMan）端口号：" port
  
  config_file_to_edit="config_${qq_number}.json"
  cat > "$config_file_to_edit" <<EOF
{
  "ob11": {
    "httpPort": 3000,
    "httpHosts": [],
    "wsPort": 3001,
    "wsHosts": [
      "ws://${ip_addr}:${port}${endpoint}"
    ],
    "enableHttp": false,
    "enableHttpPost": false,
    "enableWs": false,
    "enableWsReverse": true,
    "messagePostFormat": "string",
    "httpSecret": "",
    "enableHttpHeart": false
  },
  "heartInterval": 60000,
  "token": "",
  "enableLocalFile2Url": true,
  "debug": true,
  "log": false,
  "reportSelfMessage": false,
  "autoDeleteFile": false,
  "ffmpeg": "/usr/bin/ffmpeg",
  "autoDeleteFileSecond": 120,
  "enablePoke": false,
  "musicSignUrl": ""
}
EOF

  config_file_created=1
  
  echo "新的配置文件 ${config_file} 已创建。"
else
  echo "使用现有配置文件：${config_file_to_edit}。"
fi

if [[ -z "$config_file_created" ]]; then
  echo "当前配置文件（无界/autMan）IP: ${ip_addr}, （无界/autMan）端口: ${port}"
  read -p "是否要更改（无界/autMan）IP或者端口？(y/N): " change_ip_port_confirm
  
  if [[ $change_ip_port_confirm =~ ^[Yy]$ ]]; then
    read -p "请输入新的（无界/autMan）IP地址: " new_ip
    read -p "请输入新的（无界/autMan）端口号: " new_port
    
    update_config "$config_file_to_edit" "$new_ip" "$new_port" "$endpoint"
  fi
fi

echo "拉取并启动容器中..."
docker pull luomubiji/ntqq:latest
docker run -d  --restart=always --name NTQQ -v "/root/LLOneBot/:/opt/QQ/resources/app/LiteLoaderQQNT/data/LLOneBot/" -p 5900:5900 -p 3000:3000 docker.treebee.eu.org/luomubiji/ntqq:latest

echo "容器已成功创建并启动。"
