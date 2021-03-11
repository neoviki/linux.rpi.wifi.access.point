WIFI_SSID="pi_wifi"
WIFI_PASS="test123"


# Fix resolv.conf
echo "nameserver 8.8.8.8" > /tmp/resolv.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

sudo mv /tmp/resolv.conf /etc/resolv.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


# Restart Network Services

sudo ifconfig wlan0 down && sleep 1 && sudo ifconfig wlan0 up
sudo ifconfig eth0 down && sleep 1 && sudo ifconfig eth0 up

#Update Reop

sudo apt-get update -y
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# Fix Missing Packages

sudo apt-get update  -y --fix-missing

sudo apt-get upgrade -y

#Clean

sudo apt-get -y clean
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

sudo apt autoremove
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# Install access point software

sudo apt install -y hostapd

[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# Enable WiFi access point

sudo systemctl unmask hostapd

[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

sudo systemctl enable hostapd
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


# DNS and DHCP management software

sudo apt install -y dnsmasq
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


# Firewall Management Utility

sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent
#sudo DEBIAN_FRONTEND=noninteractive apt install -y iptables-persistent
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# DHCP server configuration

rm -rf /tmp/dhcpcd.conf; touch /tmp/dhcpcd.conf;
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

cat << EOL >>/tmp/dhcpcd.conf

interface wlan0
static ip_address=192.168.10.1/24
nohook wpa_supplicant
EOL

sudo mv  /tmp/dhcpcd.conf /etc/dhcpcd.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# Enable IP routing

rm -rf /tmp/routed-ap.conf; touch /tmp/routed-ap.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

echo "net.ipv4.ip_forward=1" > /tmp/routed-ap.conf

sudo mv /tmp/routed-ap.conf /etc/sysctl.d/routed-ap.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


# Configure IP Tables

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

sudo netfilter-persistent save
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

# Configure DHCP and DNS Server

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bkup
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

rm -rf /tmp/dnsmasq.conf; touch /tmp/dnsmasq.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

cat << EOL >> /tmp/dnsmasq.conf

interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
interface=wlan0 # interface to listen for dhcp request
dhcp-range=192.168.10.2,192.168.10.10,255.255.255.0,24h
# pool of IP addresses served via DHCP
domain=local # Local wireless domain name (DNS)
address=/pi.local/192.168.10.1   # Domain Name pi.local ( you can ping using this domain name )
EOL


sudo mv  /tmp/dnsmasq.conf /etc/dnsmasq.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


#Unblock WiFi 

sudo rfkill unblock wlan
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }


# Configure AP Software

rm -rf /tmp/hostapd.conf; touch /tmp/hostapd.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

cat << EOL >> /tmp/hostapd.conf
country_code=US
interface=wlan0
ssid=$WIFI_SSID
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WIFI_PASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

sudo mv /tmp/hostapd.conf /etc/hostapd/hostapd.conf
[ $? -ne 0 ] && { echo "error line ( ${LINENO} )"; exit 1; }

echo
echo "Configuration Details:"

echo 
echo "SSH ACCESS 1 : ssh pi@192.168.10.1"
echo 
echo "SSH ACCESS 2 : ssh pi@pi.local"
echo 
echo "WiFi SSID 	  : $WIFI_SSID"
echo
echo "WiFi PASS	  : $WIFI_PASS"
echo

# Reboot Device 
echo "reboot device for the configuration to work"
#sudo systemctl reboot



