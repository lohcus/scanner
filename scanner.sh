#!/bin/bash

vermelho="\033[31;1m"
verde="\033[32;1m"
amarelo="\033[33;1m"
normal="\033[0m"

rm relatorio_scanner.txt 2> /dev/null
rm up.txt 2> /dev/null

if [[ -z "$1" || -n "$2" ]]
then
    echo "Utilize $0 IP"
else
    regex="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
    if [[ $1 =~ $regex ]]; then
        rede=$(echo "$1" | cut -d "." -f 1-3)
        echo -e "${amarelo}\n[!] Iniciando escaneamento da rede $rede.0 [!]${normal}"
        echo "Rede: $rede.0" >> relatorio_scanner.txt
        for ((i=1;i<254;i++))
        do
            if ping -c 1 -w 1 "$rede".$i &> /dev/null
            then
                echo "$rede.$i" >> up.txt
            fi &
        done
        wait

        if [ $(cat up.txt 2> /dev/null | wc -l) -ne 0 ]; then
            ordena=$(sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n up.txt)
            echo "$ordena" > up.txt
            sed -i '/^$/d' up.txt
        else
            echo -e "${vermelho}[!] Não foi possível encontrar hosts na sub rede $rede.0 [!]\n${normal}"
            exit 0
        fi

        while read linha
        do
            echo -e "\nIP do host: $linha" >> relatorio_scanner.txt
            nmap -p 22,80,443 "$linha" | grep tcp | awk '{print $1" "$2}' >> relatorio_scanner.txt
        done < up.txt
        echo -e "${verde}[!] O scanner da rede $rede.0 foi concluído, o resultado foi gravado no arquivo relatorio_scanner.txt [!]\n${normal}"
    else
        echo -e "${vermelho}[!] O IP digitado não é válido! [!]\n${normal}"
    fi
fi