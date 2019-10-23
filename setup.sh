
modprobe xt_TPROXY
sysctl net.ipv4.ip_nonlocal_bind
sysctl net.ipv4.ip_nonlocal_bind=1

iptables -t mangle -N DIVERT
iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT

ip rule add fwmark 1 lookup 100
ip route add local 0.0.0.0/0 dev lo table 100

ip rule show
ip route show table 100
ip route show


docker network create \
    --ip-range "10.20.30.0/24" \
    --attachable \
    --driver bridge \
    --opt com.docker.network.bridge.name="proxycache0" \
    --subnet "10.20.30.0/24" \
    cachenet;

docker build -t squid -f squid.Dockerfile .
docker build -t haproxy -f haproxy.Dockerfile .

docker container run \
    --name squid \
    --network cachenet \
    --network-alias squid \
    --ip "10.20.30.40" \
    --rm \
    -d \
    -p 32080:3128 \
    squid;

docker container run \
    --name haproxy \
    --network host \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    --volume=/proc/sys/net/ipv4/ip_nonlocal_bind:/var/proc/sys/net/ipv4/ip_nonlocal_bind \
    --rm \
    -d \
    haproxy;


echo done setting up.
termterm () {
    echo shutting down...

    docker container stop squid;
    docker container stop haproxy; 
    docker network rm cachenet

    ip route del local 0.0.0.0/0 dev lo table 100
    ip rule del fwmark 1 lookup 100
    iptables -t mangle -F DIVERT
    iptables -t mangle -X DIVERT
    iptables -t mangle -D PREROUTING -p tcp -m socket -j DIVERT

    ip rule show
    ip route show table 100
    ip route show

    sysctl net.ipv4.ip_nonlocal_bind=0

    exit 128;
}

trap termterm 1 2 3 6 9 10 12 14 15


docker container logs --follow squid &
docker container logs --follow haproxy

tail -f /dev/null

sleep 15;
termterm
