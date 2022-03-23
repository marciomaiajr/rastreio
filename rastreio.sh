#!/bin/sh
#
# rastreio.sh - verifica códigos de rastreamento nos correios
#
# Site        : marciomaiajr.xyz
# Autor       : Márcio de Souza Maia Júnior
#
# -----------------------------------------------------------------------------
#
#  O programa verifica os códigos de rastreamento dos correios em um arquivo
#  e acesso uma api (linketrack) para verificar a situação das encomendas.
#
# -----------------------------------------------------------------------------
#
# Histórico:
#    v0.1 2022-03-22, Márcio de Souza Maia Júnior
#       - versão inicial do script
#
# Licença: GPL
#
# -----------------------------------------------------------------------------

###
# função acessar_api - acessa a api do linketrack para obter o
#                      status do rastreamento.
function acessar_api {
	local cod_rastreio=$1
	local str_rastreio=`curl --silent "https://api.linketrack.com/track/json?user=teste&token=1abcd00b2731640e886fb41a8a9671ad1434c599dbaa0a0de9a5aa619f29a83f&codigo=${cod_rastreio}"`
	while [ ${str_rastreio:0:3} == "Too" ]; do
		str_rastreio=`curl --silent "https://api.linketrack.com/track/json?user=teste&token=1abcd00b2731640e886fb41a8a9671ad1434c599dbaa0a0de9a5aa619f29a83f&codigo=${cod_rastreio}"`
		sleep 0.5
	done
	echo ${str_rastreio}
}

filename='./encopend'
n=0
# verifica se o arquivo existe
if [ ! -f "${filename}" ]; then
	echo "${filename} não encontrado. Processamento encerrado"
	exit 1
fi

# verifica se o arquivo tem conteúdo
if [ ! -s "${filename}" ]; then
	echo "${filename} vazio. Processamento encerrado."
	exit 1
fi
# para cada linha do arquivo execute
while read line; do
	# obtem código de rastreio primeiro campo do arquivo
	cod_rastreio=`echo $line | cut -f1 -d';'`
	# exibe código ao usuário
	echo "Código de rastreio: " $cod_rastreio
	# obtem string de rastreio vinda da api
	str_rastreio=$(acessar_api $cod_rastreio)
	# reseta o contador
	i=0
	str_evento=`echo $str_rastreio | jq ".eventos[$i]"`
	while [ "${str_evento:0:4}" != "null" ]; do
		str_status=`echo $str_rastreio | jq ".eventos[$i].status"`
		str_local=`echo $str_rastreio | jq ".eventos[$i].local"`
		str_data=`echo $str_rastreio | jq ".eventos[$i].data"`
		str_hora=`echo $str_rastreio | jq ".eventos[$i].hora"`
		echo $str_status $str_local $str_data $str_hora
		i=$((i+1))
		str_evento=`echo $str_rastreio | jq ".eventos[$i]"`
	done
done < ${filename}
