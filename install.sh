#!/bin/bash

#Você pode usar o APP ShadowSocks da PlayStore, ou o software Outline (https://www.getoutline.org/en/home) para plataformas Windows/Linux/Mac/Android
#Ao fim da instalação, você obterá a chave de acesso para inserir no OutLine!

##->PARA BAIXAR E EXECUTAR: wget -O setup.sh [ENDEREÇO RAW] && sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh <-##

#Apresentação
echo "`echo $'\n> '` Bem vindo a instalação do shadowsocks! `echo $'\n> '` script rápido feito por @cassianopontes.com... `echo $'\n> '` forneça as informações personalizadas `echo $'\n> '` ou vai teclando [enter] que farei tudo para você!"
sleep 5
IPPUB=$(curl -s "http://whatismyip.akamai.com")
NAMELINE=$(hostname)
#Checar se o serviço já existe
if [ -f /usr/bin/ssserver ]; then
    echo "`echo $'\n> '`[ERROR] Este servidor já tem um shadowsocks! remova-o!"
    echo "pip uninstall shadowsocks"
    exit
elif [ -f /usr/local/bin/ssserver ]; then
    echo "`echo $'\n> '`[ERROR] Este servidor já tem um shadowsocks! remova-o!"
    echo "pip uninstall shadowsocks"
    exit
fi

#Solicitar porta
read -p "`echo $'\n> '`Instalar shadowsocks na porta: [10-9999] " -e -i 80 PORTA
USE=$( (>/dev/tcp/localhost/$PORTA) &>/dev/null || echo 1)

#Testar condições da porta inserida
if ! [[ "$PORTA" =~ ^[0-9]+$ ]]
    then
    echo "[ERROR] Não insira letras na porta!"
	exit
elif [ "$USE" != "1" ];then
	echo "`echo $'\n> '`[ERROR] A Porta está em uso por outro processo..."
	echo "`echo $'\n> '`Saindo..."
	exit
elif [ $PORTA -lt 10 ];then
	echo "`echo $'\n> '`[ERROR] A Porta tem que ser maior que 10"
	echo "`echo $'\n> '`Saindo..."
	exit
elif [ $PORTA -gt 9999 ];
    then
    echo "`echo $'\n> '`[ERROR] A Porta tem que ser menor que 9999!"
	echo "`echo $'\n> '`Saindo..."
    exit
fi

echo "`echo $'\n> '`[SUCCESS] A Porta $PORTA parece está livre! vamos continuar..."

#Obter informações sobre IP
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
read -p "`echo $'\n> '`Seu IP:PORTA é: $IP:$PORTA ? `echo $'\n> '`Se o IP Acima está correto, tecle enter! `echo $'\n> '`[Você pode apagar este IP e informar outro...]`echo $'\n> '`IP da minha placa é: " -e -i $IP IPEXT
if [ "$IPEXT" != "$IP" -a "$IPEXT" != "" ];
then
	read -p "`echo $'\n> '`Você alterou o IP da sua placa principal `echo $'\n> '`IP detectado: $IP | IP Informado: $IPEXT `echo $'\n> '`[WARN]Se o IP informado estiver errado, não irá funcionar!`echo $'\n> '`Deseja confirmar a mudança de IP? [ sim / nao ]`echo $'\n> '`" -e -i "sim" CONFIRMA
	if [ "$CONFIRMA" = "sim"  ];then
		IP=$IPEXT
	fi
fi

#Cria um salto numérico
SALT=$(( ( RANDOM % 1000 )  + 1 ))

#Obter senha
read -p "`echo $'\n> '`Senha para o shadowsocks: " -e -i "100617L$SALT" SENHA
	if [ -z $SENHA ];then
		echo "`echo $'\n> '`Digite uma senha na próxima vez! Saindo..."
		exit
	fi

#Obter método de criptografia
read -p "`echo $'\n> '`Digite um método de criptografia: `echo $'\n> '`1 para BF-CFB [+ rápido + inseguro]`echo $'\n> '`2 para AES-256-CFB [+/- rápido +/- seguro]`echo $'\n> '`3 para AES-256-CTR [- rápido + seguro]`echo $'\n> '`Você poderá alterar o método em /etc/shadowsocks.json`echo $'\n> '`Método: " -e -i 1 CRYPTO
if ! [[ "$CRYPTO" =~ ^[0-9]+$ ]]
    then
    echo "[ERROR] Não insira letras!"
	exit
elif [ $CRYPTO -lt  1 ];then
	echo "`echo $'\n> '`[ERROR] A crypto tem que ser maior que 0"
	echo "`echo $'\n> '`Saindo..."
	exit
elif [ "$CRYPTO" -gt 3 ];then
    echo "`echo $'\n> '`[ERROR] A crypto tem que ser menor que 4!"
	echo "`echo $'\n> '`Saindo..."
    exit
elif [ $CRYPTO = "1" ];then
	CRYPTO="bf-cfb"
elif [ "$CRYPTO" = "2" ];then
	CRYPTO="aes-256-cfb"
elif [ "$CRYPTO" = "3" ];then
	CRYPTO="aes-256-ctr"
fi

#Cria configuração da JSON
JSON=$(cat <<-END
    {
	"server":"$IP",
	"server_port":$PORTA,
	"local_port":1080,
	"password":"$SENHA",
	"timeout":600,
	"method":"$CRYPTO",
	"fast_open": true
	}
END
)

#Executa e instala programas cruciais para o funcionamento do socks
echo "`echo $'\n> '`[PASSO1] atualizando o repositório..."
apt update

echo "`echo $'\n> '`[PASSO2] instalando pip..."
apt install python3.6
apt install python-setuptools
apt install python3-setuptools
wget https://files.pythonhosted.org/packages/36/fa/51ca4d57392e2f69397cd6e5af23da2a8d37884a605f9e3f2d3bfdc48397/pip-19.0.3.tar.gz
tar -xzvf pip-19.0.3.tar.gz
cd pip-19.0.3
python3 setup.py install

echo "`echo $'\n> '`[PASSO3] instalando shadowsocks..."
pip install shadowsocks

echo "`echo $'\n> '`[PASSO4] instalando m2crypto..."
apt install python-m2crypto

echo "`echo $'\n> '`[PASSO5] instalando build-essential..."
apt install build-essential

echo "`echo $'\n> '`[PASSO6] instalando libsodium..."
wget https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz
tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
./configure && make && make install
ldconfig

echo "`echo $'\n> '`[PASSO7] criando config do shadowsocks..."
echo $JSON > /etc/shadowsocks.json

echo "`echo $'\n> '`[PASSO8] iniciando shadowsocks..."
ssserver -c /etc/shadowsocks.json -d start

printf "\nnet.ipv4.tcp_fastopen=3\n" >> /etc/sysctl.conf

#Gera chave para outline
outline=$(echo -ne "$CRYPTO:$SENHA@$IPPUB:$PORTA" | base64);

#Avisa ao usuário que a instalação terminou!
echo "`echo $'\n> '`########## A INSTALAÇÃO TERMINOU! ###########"
echo "`echo $'\n> '`########## A CHECAR SE ESTÁ OK... ###########"
sleep 3

#Obter o caminho do serviço para checar se está rodando
if [ -f /usr/bin/ssserver ]; then
    DAEMON=/usr/bin/ssserver
elif [ -f /usr/local/bin/ssserver ]; then
    DAEMON=/usr/local/bin/ssserver
fi

#Obter PID do serviço
PIDT=$(ps -ef | grep -v grep | grep -i "${DAEMON}" | awk '{print $2}')

#Testar se está OK
if [ -n "$PIDT" ];then
       echo "`echo $'\n> '`[OK] Seu servidor está rodando normal!"
       echo "`echo $'\n> '`Ajuda com isso? contato@cassianopontes.com"
else 
    echo "`echo $'\n> '`[ERROR] Seu servidor não está rodando!"
	echo "`echo $'\n> '`Vamos tentar corrigir... aguarde!"
	sleep 3
	if [ -f /usr/bin/python3 ]; then
	  	RESULT=$(python3 -c "import site; print(site.getsitepackages())")
		IFS=', ' read -r -a array <<< "$RESULT"
		PATCH="${array[0]}"
	else
	    RESULT=$(python -c "import site; print(site.getsitepackages())")
		IFS=', ' read -r -a array <<< "$RESULT"
		PATCH="${array[0]}"
	fi
	PATCH=$(sed -e "s/^\['//" -e "s/'$//"<<<"$PATCH")
	sed -i -e 's/EVP_CIPHER_CTX_cleanup/EVP_CIPHER_CTX_reset/g' $PATCH/shadowsocks/crypto/openssl.py
	echo "`echo $'\n> '`Correção aplicada! tentando iniciar..."
	sleep 2
	ssserver -c /etc/shadowsocks.json -d start
	sleep 2
	PIDT=$(ps -ef | grep -v grep | grep -i "${DAEMON}" | awk '{print $2}')
	if [ -n "$PIDT" ];then
		 echo "`echo $'\n> '`[OK] Seu servidor está rodando normal!"
       	 echo "`echo $'\n> '`Ajuda com isso? contato@cassianopontes.com"
	else
		echo "`echo $'\n> '`[ERROR] Seu servidor ainda não está rodando!"
		echo "`echo $'\n> '` !!! tente consultar /var/log/shadowsocks.log !!!"
		echo "`echo $'\n> '`Observe se a porta escolhida está em uso por outro processo!"
    	echo "`echo $'\n> '`Ajuda com isso? contato@cassianopontes.com"
    	exit
	fi
    
fi
	#Pergunta se o usuário quer adicionar a regra de iniciar o SS sozinho ao BOOT
	read -p "`echo $'\n> '`Você quer iniciar o shadowsocks automaticamente? [sim / nao] " -e -i "sim" AUTO
	if [ "$AUTO" = "sim"  ];then
			ssserver -c /etc/shadowsocks.json -d stop
			/usr/bin/python3 /usr/local/bin/ssserver -c /etc/shadowsocks.json -d start
			echo "`echo $'\n> '`Agora o shadowsocks inicia automaticamente!"
	fi

	#Pergunta se o usuário quer aplicar alumas melhorias para o tráfego TCP
	read -p "`echo $'\n> '`Você quer aplicar uma melhoria de performance? [sim / nao] " -e -i "sim" PERF
	if [ "$PERF" = "sim"  ];then
			printf "* soft nofile 51200\n* hard nofile 51200\n" >> /etc/security/limits.conf
			ssserver -c /etc/shadowsocks.json -d stop
			ulimit -n 51200
	cat <<EOT >> /etc/sysctl.conf

#Adicionado pelo script do shadowsocks
fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla
EOT
#Aplica as config e inicia o shadowsocks
		sysctl -p
		ssserver -c /etc/shadowsocks.json -d start
		echo "`echo $'\n> '`Regras adicionadas ao /etc/sysctl.conf..."
fi

#Finaliza e mostra as informações de conexão

echo "`echo $'\n> '`------------------------------" 
echo "" 
echo "--------IP: $IPPUB---------" 
echo "--------Porta: $PORTA---------------" 
echo "--------Metódo: $CRYPTO-----" 
echo "--------Senha: $SENHA--------"
echo "`echo $'\n> '`-----------------------------"
echo "`echo $'\n> '`Cliente multiplataforma: https://www.getoutline.org/en/home"
echo "`echo $'\n> '`CHAVE PARA SE CONECTAR PELO OUTLINE: "
echo "`echo $'\n> '`ss://$outline#$NAMELINE"
