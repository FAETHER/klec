sudo openvpn --config ./vpn/FR/FreeVPN.it-UDP-40000.ovpn --daemon

ip_address="192.168.2.1"
netmask="255.255.255.0"
dhcp_range_start="192.168.2.2"
dhcp_range_end="192.168.2.100"
dhcp_time="12h"
eth="eth0"
wlan="tun0"

sudo systemctl start network-online.target &> /dev/null

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o $wlan -j MASQUERADE
sudo iptables -A FORWARD -i $wlan -o $eth -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $eth -o $wlan -j ACCEPT

sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

sudo ifconfig $eth $ip_address netmask $netmask

# Remove default route created by dhcpcd
sudo ip route del 0/0 dev $eth &> /dev/null

sudo systemctl stop dnsmasq

sudo rm -rf /etc/dnsmasq.conf

#sudo rm -rf /etc/dnsmasq.d/* &> /dev/null

sudo echo -e "interface=$eth\n\
bind-interfaces\n\
server=8.8.8.8\n\
domain-needed\n\
bogus-priv\n\
dhcp-range=$dhcp_range_start,$dhcp_range_end,$dhcp_time" > /etc/dnsmasq.conf

sudo systemctl start dnsmasq
