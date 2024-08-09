#!/bin/bash

if [ -z "$MONIKER" ]; then
  echo "*********************"
  echo -e "\e[1m\e[34m		Погрузись в мир Web3 вместе с https://web3easy.media\e[0m"
  echo "*********************"
  echo -e "\e[1m\e[32m	Создайте имя вашей ноды:\e[0m"
  echo "*********************"
  read MONIKER
  echo 'export MONIKER='$MONIKER >> $HOME/.bash_profile
  source ~/.bash_profile
fi

echo "*****************************"
echo -e "\e[1m\e[32m Node moniker:       $MONIKER \e[0m"
echo -e "\e[1m\e[32m Chain id:           $NODE_CHAIN_ID \e[0m"
echo -e "\e[1m\e[32m Chain demon:        $CHAIN_DENOM \e[0m"
echo -e "\e[1m\e[32m Binary version tag: $BINARY_VERSION_TAG \e[0m"
echo -e "\e[1m\e[32m Binary name:        $BINARY_NAME \e[0m"
echo -e "\e[1m\e[32m Directory:          $DIRECTORY \e[0m"
echo -e "\e[1m\e[32m Hidden directory:   $HIDDEN_DIRECTORY \e[0m"
echo "*****************************"
sleep 1

PS3='Select an action: '
options=("Создать новый кошелек" "Восстановить кошелек" "Выход")
select opt in "${options[@]}"
do
  case $opt in
    "Создать новый кошелек")
      command="$BINARY_NAME keys add wallet"
      break
      ;;
    "Восстановить кошелек")
      command="$BINARY_NAME keys add wallet --recover"
      break
      ;;
    "Выход")
      exit
      ;;
    *) echo "Ошибка. Повторите попытку.";;
  esac
done

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Обновление пакетов и зависимостей *****/////]] \e[0m" && sleep 1
#UPDATE APT
sudo apt update && apt upgrade -y
apt install bc curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Установка GO *****/////]] \e[0m" && sleep 1
#INSTALL GO
# source <(curl -s https://raw.githubusercontent.com/Collieries/system/main/go)

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Загрузка и создание двоичных файлов *****/////]] \e[0m" && sleep 1
#INSTALL
cd $HOME
git clone $NODE_URL && cd $DIRECTORY
git fetch --all
git checkout $BINARY_VERSION_TAG
if [ $BINARY_NAME == "lavad" ]; then make install-all; else make install; fi
TEMP=$(which $BINARY_NAME)
sudo cp $TEMP /usr/local/bin/ && cd $HOME
$BINARY_NAME version --long | grep -e version -e commit

$BINARY_NAME init $MONIKER --chain-id $NODE_CHAIN_ID

wget -O $HOME/$HIDDEN_DIRECTORY/config/genesis.json $GENESIS_URL

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Порты установлены *****/////]] \e[0m" && sleep 1
external_address=$(curl -s https://checkip.amazonaws.com)
# config.toml
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NODE_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://${external_address}:${NODE_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NODE_PORT}061\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NODE_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NODE_PORT}660\"%" $HOME/$HIDDEN_DIRECTORY/config/config.toml
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:${NODE_PORT}656\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml
# app.toml
sed -i.bak -e "s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NODE_PORT}90\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NODE_PORT}91\"%; s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:1${NODE_PORT}7\"%" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i.bak -e "s%^address = \"localhost:9090\"%address = \"localhost:${NODE_PORT}90\"%; s%^address = \"localhost:9091\"%address = \"localhost:${NODE_PORT}91\"%; s%^address = \"tcp://localhost:1317\"%address = \"tcp://localhost:1${NODE_PORT}7\"%" $HOME/$HIDDEN_DIRECTORY/config/app.toml
# client.toml
sed -i.bak -e "s%^node *=.*\"%node = \"tcp://${external_address}:${NODE_PORT}657\"%" $HOME/$HIDDEN_DIRECTORY/config/client.toml

ufw allow ${NODE_PORT}657

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\*****Конфигурация уствновлена*****/////]] \e[0m" && sleep 1

# Set the minimum price for gas
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"$MINIMUM_GAS_PRICES\"/;" ~/$HIDDEN_DIRECTORY/config/app.toml

# Add seeds/peers в config.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml
sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

# Set up filter for "bad" peers
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

# Set up pruning
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml
sed -i -e "s/^snapshot-interval *=.*/snapshot-interval = \"$snapshot_interval\"/" $HOME/$HIDDEN_DIRECTORY/config/app.toml

sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/$HIDDEN_DIRECTORY/config/config.toml

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Кошелек установлен *****/////]] \e[0m" && sleep 1

if [ "$NODE_NAME" == "BABYLON" ]; then
sed -i -e "s/^key-name *=.*/key-name = \"wallet\"/" ~/.babylond/config/app.toml
sed -i -e "s/^timeout_commit *=.*/timeout_commit = \"30s\"/" ~/.babylond/config/config.toml
sed -i -e "s/^network *=.*/network = \"signet\"/" $HOME/.babylond/config/app.toml
command="$command --keyring-backend test"
else
# correct config (so we can no longer use the chain-id flag for every CLI command in client.toml)
$BINARY_NAME config chain-id $NODE_CHAIN_ID
# adjust if necessary keyring-backend в client.toml 
$BINARY_NAME config keyring-backend test
$BINARY_NAME config node tcp://${external_address}:${NODE_PORT}657
fi

# Execute the saved command
eval "$command"

echo "export ${NODE_NAME}_CHAIN_ID="${NODE_CHAIN_ID} >> $HOME/.bash_profile

if [ "$NODE_NAME" == "BABYLON" ]; then
ADDRESS=$($BINARY_NAME keys show wallet -a --keyring-backend test)
VALOPER=$($BINARY_NAME keys show wallet --bech val -a --keyring-backend test)
babylond create-bls-key $ADDRESS
else
ADDRESS=$($BINARY_NAME keys show wallet -a)
VALOPER=$($BINARY_NAME keys show wallet --bech val -a)
fi

echo "export ${NODE_NAME}_ADDRESS="${ADDRESS} >> $HOME/.bash_profile
echo "export ${NODE_NAME}_VALOPER="${VALOPER} >> $HOME/.bash_profile
source $HOME/.bash_profile

#==================================================================================================

echo -e "\e[1m\e[32m [[\\\\\***** Установка сервисных файлов *****/////]] \e[0m" && sleep 1

# Create service file (One command)
if [ "$BINARY_NAME" == "0gchaind" ]; then
sudo tee /etc/systemd/system/Ogchaind.service > /dev/null <<EOF
[Unit]
Description=$NODE_NAME Node
After=network.target
 
[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/go/bin
ExecStart=/usr/local/bin/$BINARY_NAME start
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200
 
[Install]
WantedBy=multi-user.target
EOF

else
sudo tee /etc/systemd/system/$BINARY_NAME.service > /dev/null <<EOF
[Unit]
Description=$NODE_NAME Node
After=network.target
 
[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/go/bin
ExecStart=/usr/local/bin/$BINARY_NAME start
Restart=on-failure
StartLimitInterval=0
RestartSec=3
LimitNOFILE=65535
LimitMEMLOCK=209715200
 
[Install]
WantedBy=multi-user.target
EOF
fi

# Start the node
systemctl daemon-reload
if [ "$BINARY_NAME" == "0gchaind" ]; then
systemctl enable Ogchaind
systemctl restart Ogchaind
echo '=============== SETUP FINISHED ==================='
echo -e 'Статус ноды:        \e[1m\e[32mАктивна\e[0m'
echo -e "Для проверки логов введите команду:        \e[1m\e[33mjournalctl -u Ogchaind -f -o cat\e[0m"
else
systemctl enable $BINARY_NAME
systemctl restart $BINARY_NAME
echo '=============== SETUP FINISHED ==================='
echo -e 'Статус ноды:        \e[1m\e[32mАктивна\e[0m'
echo -e "Для проверки логов введите команду:        \e[1m\e[33mjournalctl -u $BINARY_NAME -f -o cat\e[0m"
fi

echo -e "Для проверки синхронизации введите команду: \e[1m\e[35mcurl localhost:${NODE_PORT}657/status\e[0m"
