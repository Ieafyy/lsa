cp ./lsa.sh /usr/local/bin/lsa
if [ $? -ne 0 ]; then
    echo "Erro ao instalar o comando lsa"
    exit 1
fi
echo "Instalado com sucesso!"
chmod +x /usr/local/bin/lsa
