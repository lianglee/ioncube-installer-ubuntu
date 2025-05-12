#!/bin/bash

# Step 1: Detect PHP version
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
PHP_EXT_DIR=$(php -i | grep "^extension_dir" | awk '{print $3}')
ARCH=$(uname -m)

if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="x86-64"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

echo "Detected PHP version: $PHP_VERSION"
echo "PHP extension directory: $PHP_EXT_DIR"

# Step 2: Download ionCube
cd /tmp || exit
IONCUBE_TAR="ioncube_loaders_lin_${ARCH}.tar.gz"
IONCUBE_URL="https://downloads.ioncube.com/loader_downloads/$IONCUBE_TAR"

echo "Downloading ionCube Loader..."
curl -O "$IONCUBE_URL" || { echo "Download failed!"; exit 1; }

# Step 3: Extract and copy the correct loader
tar -xzf "$IONCUBE_TAR"
IONCUBE_SO="ioncube_loader_lin_${PHP_VERSION}.so"

if [ ! -f "ioncube/$IONCUBE_SO" ]; then
  echo "ionCube loader for PHP $PHP_VERSION not found!"
  exit 1
fi

sudo cp "ioncube/$IONCUBE_SO" "$PHP_EXT_DIR"

# Step 4: Enable ionCube in PHP config
INI_FILE="/etc/php/$PHP_VERSION/cli/conf.d/00-ioncube.ini"
echo "zend_extension=$PHP_EXT_DIR/$IONCUBE_SO" | sudo tee "$INI_FILE"

# Also enable for Apache or FPM if present
if [ -d "/etc/php/$PHP_VERSION/apache2/conf.d" ]; then
  sudo cp "$INI_FILE" "/etc/php/$PHP_VERSION/apache2/conf.d/00-ioncube.ini"
  echo "Enabled ionCube for Apache"
  sudo systemctl restart apache2
fi

if [ -d "/etc/php/$PHP_VERSION/fpm/conf.d" ]; then
  sudo cp "$INI_FILE" "/etc/php/$PHP_VERSION/fpm/conf.d/00-ioncube.ini"
  echo "Enabled ionCube for PHP-FPM"
  sudo systemctl restart php$PHP_VERSION-fpm
fi

# Step 5: Verify installation
php -v | grep -i ioncube && echo "ionCube successfully installed!" || echo "ionCube installation failed."