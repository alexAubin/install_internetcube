# Install apt dependencies

# Most of these are deps of vpnclient and hotspot and we install them to speed
# up the install process later

APT_DEPS="file jq sipcalc hostapd iptables iw dnsutils 
openvpn curl fake-hwclock
firmware-linux-free
php-cli php-common php-intl php-json php-pear php-auth-sasl php-mail-mime
php-patchwork-utf8 php-net-smtp php-net-socket php-zip php-gd php-mbstring
php-curl
python3-venv avahi-utils python3-setuptools python3-wheel"

apt install -o Dpkg::Options::='--force-confold' $APT_DEPS -y

# Initialize venv with pip dependencies

python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install -r requirements.txt
deactivate

# Configure avahi aliases (internetcube.local, briqueinternet.local)

cp deploy/avahi-alias.service /etc/systemd/system/avahi-alias@.service
systemctl enable avahi-alias@internetcube.local.service
systemctl enable avahi-alias@briqueinternet.local.service

[ -n "$YNH_BUILDER_INSTALL_INTERNETCUBE" ] || systemctl start avahi-alias@internetcube.local.service
[ -n "$YNH_BUILDER_INSTALL_INTERNETCUBE" ] || systemctl start avahi-alias@briqueinternet.local.service

# Configure nginx + ssowat

cp deploy/nginx.conf /etc/nginx/conf.d/default.d/internetcube_install.conf
[ -n "$YNH_BUILDER_INSTALL_INTERNETCUBE" ] || systemctl reload nginx

echo '{"redirected_urls": { "/": "/install" }}' > /etc/ssowat/conf.json.persistent

# Configure systemd service for flask app

cp deploy/internetcube.service /etc/systemd/system/
[ -n "$YNH_BUILDER_INSTALL_INTERNETCUBE" ] || systemctl daemon-reload
systemctl enable internetcube
[ -n "$YNH_BUILDER_INSTALL_INTERNETCUBE" ] || systemctl start internetcube

# Flag the cube as "to be installed"

touch /etc/yunohost/internetcube_to_be_installed

