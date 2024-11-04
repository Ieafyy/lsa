editor='zed'
max_per_page=20

getValues() {
    values=($(ls -A .))
    index=0
    page=0
    values_len=${#values[@]}
}

getValues

displayValues() {
    clear
    if [[ -z $1 ]]; then
        local j=0
        local j_loop=0
    else
        local j=$1
        local j_loop=$(( j * max_per_page ))
    fi
    echo "Diretorio atual: $(pwd)"
    echo "$values_len arquivos | pagina ${j}/$(( values_len / max_per_page ))"
    echo "------------------------------------"
    for (( i=$j_loop; i<${#values[@]}; i++ )); do
        if [[ $i -eq $index ]]; then
            if [[ -d ${values[i]} ]]; then
                echo -e "\uf07b \e[7m${values[i]}\e[0m"
            else
                echo -e "\uf15b \e[7m${values[i]}\e[0m"
            fi
        else
            if [[ -d ${values[i]} ]]; then
                echo -e "\uf07b ${values[i]}"
            else
                echo -e "\uf15b ${values[i]}"
            fi
        fi

        if [[ $i -gt $(( max_per_page * (j + 1) )) ]]; then
            echo '...'
            break
        fi
    done
    echo "------------------------------------"
    #tput cup 0 0
}



while true; do
    displayValues $page
    echo -e "\e[?25l"
    read -sn1 key
    if [[ $key == $'\e' ]]; then
        read -sn1 -t 0.1 key
        if [[ $key == "[" ]]; then
            read -sn1 -t 0.1 key
            if [[ $key == 'A' ]]; then
                if [[ $index -lt 1 ]]; then
                    :
                else
                  (( index-- ))
                fi
            elif [[ $key == 'B' ]]; then
                if [[ $index -gt $(( values_len - 2  )) ]]; then
                    :
                else
                    (( index++ ))
                fi
            elif [[ $key == 'C' && $page -lt $(( values_len / max_per_page )) ]]; then
                displayValues $(( page++ ))
                (( index += max_per_page ))
            elif [[ $key == 'D' && $page -gt 0 ]]; then
                displayValues $(( page-- ))
                (( index -= max_per_page ))
            fi
        else
            getValues
            displayValues $page
        fi

    elif [[ $key == 'a' || $key == '' ]]; then
        if [[ -f "${values[$index]}" ]]; then
            $editor "${values[$index]}"
        else
            cd "${values[$index]}"
            getValues
            displayValues $page
        fi

    elif [[ $key == 'q' ]]; then
        echo -e "\e[?25h"
        clear
        echo $(pwd)
        break

    elif [[ $key == 's' ]]; then
        cd ..
        getValues
        displayValues $page

    elif [[ $key == 'd' ]]; then
        $editor "$PWD"

    elif [[ $key == 'x' && $page -lt $(( values_len / max_per_page )) ]]; then
        displayValues $(( page++ ))
        (( index += max_per_page ))

    elif [[ $key == 'z' && $page -gt 0 ]]; then
        displayValues $(( page-- ))
        (( index -= max_per_page ))

    elif [[ $key == '/' ]]; then
        read -p "Pesquisar: " search
        echo $search
        values=($(echo ${values[@]} | tr ' ' '\n' | grep $search))
        values_len=${#values[@]}

    elif [[ $key == '.' ]]; then

        read -p "Novo arquivo: (/ para diretorio) " name
        echo $name
        if echo $name | grep -qP '^/'; then
            mkdir -p $PWD$name
        else
            touch $PWD/$name
        fi
        getValues
        displayValues $page

    elif [[ $key == 'r' ]]; then
        read -p "Remover ${values[$index]}: (y/n) " name
        if [[ $name == 'y' ]]; then
            rm -rf ${values[$index]}
            getValues
            displayValues $page
        else
            :
        fi

    elif [[ $key == 'f' ]]; then
        read -p "Novo nome: " name
        mv ${values[$index]} $name
        getValues
        displayValues $page

    elif [[ $key == 'h' ]]; then
        clear
        echo "a: abrir arquivo/diretorio"
        echo "s: voltar um diretorio"
        echo "d: abrir diretorio no editor"
        echo "q: sair"
        echo "x: proxima pagina"
        echo "z: pagina anterior"
        echo "/: pesquisar"
        echo ".: criar arquivo/diretorio"
        echo "r: remover arquivo/diretorio"
        echo "f: renomear arquivo/diretorio"
        echo "h: ajuda"
        read -sn1
        getValues
        displayValues $page
    fi

done
