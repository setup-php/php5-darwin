version=$1
php_version="php$version"
ini_file="/opt/local/etc/php$version/php.ini"
github_link="https://github.com/"
github_repo="$github_link/shivammathur/php5-darwin"
php_etc_dir="/opt/local/etc/php$version"
tmp_path="/tmp/php$version"
export TERM=xterm

# Function to switch PHP version
switch_version() {
  for tool in php phpize php-config; do
    sudo mv /opt/local/bin/"$tool$version" /opt/local/bin/"$tool"
  done
  sudo ln -sf /opt/local/bin/* /usr/local/bin
}

# Function to setup PHP
setup_php() {
  curl -o "$tmp_path".tar.zst -sSL "$github_repo"/releases/latest/download/"$php_version".tar.zst
  zstdcat "$tmp_path".tar.zst --no-progress - | tar -xf - -C /tmp
  sudo installer -pkg "$tmp_path"/"$php_version".mpkg -target /
  sudo cp -a "$tmp_path"/lib/* /opt/local/lib
  sudo cp "$php_etc_dir"/php.ini-development "$php_etc_dir"/php.ini
  sudo chmod 777 "$ini_file"
  echo "date.timezone=UTC" >>"$ini_file"
}

# Function to add extensions
add_extensions() {
  ext_dir=$(php -i | grep -Ei "extension_dir => /" | sed -e "s|.*=> s*||")
  sudo mkdir -p "$ext_dir"
  sudo cp -a "$tmp_path"/ext/*.so "$ext_dir"
  sudo installer -pkg "$tmp_path"/"$php_version"-opcache.pkg -target /
  for bin in "$tmp_path"/ext/*.so; do
    extension=$(basename "$bin" | cut -d'.' -f 1)
    echo "extension=$extension.so" >>"$ini_file"
  done
}

# Function to add pear
add_pear() {
  pecl_version='master'
  if [ "$version" = "53" ]; then
    pecl_version='v1.9.5'
  fi
  pear_github_repo="$github_link/pear/pearweb_phars"
  sudo curl -o /tmp/pear.phar -sSL "$pear_github_repo/raw/$pecl_version/install-pear-nozlib.phar"
  sudo php /tmp/pear.phar -d /opt/local/lib/"$php_version" -b /usr/local/bin
}

setup_php
switch_version
add_extensions
add_pear