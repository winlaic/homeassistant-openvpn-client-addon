#!/usr/bin/env bash
set +u

CONFIG_PATH=/data/options.json

OVPNFILE="$(jq --raw-output '.ovpnfile' $CONFIG_PATH)"
INTERFACE="$(jq --raw-output '.interface' $CONFIG_PATH)"
OPENVPN_CONFIG=/share/${OVPNFILE}
OPENVPN_SERVER_ADDR=$(cat "${OPENVPN_CONFIG}" | grep -oP '(?<=remote\s)\d+(\.\d+){3}')

########################################################################################################################
# Initialize the tun interface for OpenVPN if not already available
# Arguments:
#   None
# Returns:
#   None
########################################################################################################################
function init_tun_interface(){
    # create the tunnel for the openvpn client

    mkdir -p /dev/net
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi
}

get_ipv4() {
    local interface="$1"
    
    # 使用 ip 命令获取 IPv4 地址（推荐方式）
    local ipv4=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # 如果 ip 命令失败，尝试使用 ifconfig（兼容旧系统）
    if [ -z "$ipv4" ]; then
        ipv4=$(ifconfig "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    fi
    
    # 输出结果
    if [ -n "$ipv4" ]; then
        echo "$ipv4"
        return 0
    else
        echo "错误：无法获取接口 $interface 的 IPv4 地址" >&2
        return 1
    fi
}

get_gateway_ipv4() {
    local interface="$1"
    
    # 方法1：使用 ip route 获取网关（推荐）
    local gateway=$(ip -4 route show dev "$interface" | awk '/default/ {print $3}')
    
    # 方法2：如果 ip 命令失败，尝试使用 netstat（兼容旧系统）
    if [ -z "$gateway" ]; then
        gateway=$(netstat -rn | grep -E "^0.0.0.0.*$interface" | awk '{print $2}')
    fi
    
    # 输出结果
    if [ -n "$gateway" ]; then
        echo "$gateway"
        return 0
    else
        echo "错误：无法获取接口 $interface 的默认网关 IPv4 地址" >&2
        return 1
    fi
}

INTERFACE_GATEWAY_ADDR=$(get_gateway_ipv4 "${INTERFACE}")


########################################################################################################################
# Check if all required files are available.
# Globals:
#   REQUIRED_FILES
#   STORAGE_LOCATION
# Arguments:
#   None
# Returns:
#   0 if all files are available and 1 otherwise
########################################################################################################################
function check_files_available(){
    failed=0

    if [[ ! -f ${OPENVPN_CONFIG} ]]
    then
        echo "File ${OPENVPN_CONFIG} not found"
        failed=1
        break
    fi

    if [[ ${failed} == 0 ]]
    then
        return 0
    else
        return 1
    fi


}

########################################################################################################################
# Wait until the user has uploaded all required certificates and keys in order to setup the VPN connection.
# Globals:
#   REQUIRED_FILES
#   CLIENT_CONFIG_LOCATION
# Arguments:
#   None
# Returns:
#   None
########################################################################################################################
function wait_configuration(){

    echo "Wait until the user uploads the files."
    # therefore, wait until the user upload the required certification files
    while true; do

        check_files_available

        if [[ $? == 0 ]]
        then
            break
        fi

        sleep 5
    done
    echo "All files available!"
}

init_tun_interface

# wait until the user uploaded the configuration files
wait_configuration

echo "Setup the VPN connection with the following OpenVPN configuration."
cat ${OPENVPN_CONFIG}

ip route add "${OPENVPN_SERVER_ADDR}" via "${INTERFACE_GATEWAY_ADDR}" dev "${INTERFACE}"

# try to connect to the server using the used defined configuration
openvpn --config ${OPENVPN_CONFIG}
