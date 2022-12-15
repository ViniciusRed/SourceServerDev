# Safety check
pacman-key --init

# Updating Database
pacman -Syy

# Installing packages
pacman --noconfirm -S bottom openssh sudo nginx mariadb
pacman --noconfirm -U *pkg.tar.zst

# Services that starts
systemctl enable CSS
systemctl enable check

# Updating Steam files
steamcmd +quit

# Delete Files
rm Install.sh
rm *pkg.tar.zst
