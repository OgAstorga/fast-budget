#!/bin/bash


######
# Load .env vars
declare -a config_envs=(
  ".env.base"
  ".env"
)

for env_file in "${config_envs[@]}"
do
  if [ -f $env_file ]; then
    source $env_file
  fi
done


#####
# Make sure that release path (relative/absolute) exists
mkdir -p $RELEASE_PATH


######
USER=$(whoami)
BUNDLE=$(which bundle)
RELEASE_PATH="$(readlink -e $RELEASE_PATH)"
CREL_PATH=$RELEASE_PATH/current
SYSTEMD_PATH="/etc/systemd/system/${SLUG}d.service"


######
echo "installing as a systemd unit"
echo "[Unit]
Description=$NAME

[Service]
Type=simple
RemainAfterExit=yes
User=$USER
WorkingDirectory=$CREL_PATH
ExecStart=$BUNDLE exec thin -R $CREL_PATH/config.ru -C $CREL_PATH/thin.yml start
ExecStop=$BUNDLE exec thin -R $CREL_PATH/config.ru -C $CREL_PATH/thin.yml stop
TimeoutSec=300

[Install]
WantedBy=multi-user.target" | sudo tee $SYSTEMD_PATH
printf "done\n\n"


######
echo "finished."
