#!/bin/bash

editor='zed'
#max_per_page=`tput lines`
#max_per_page=$(( max_per_page / 2 ))
max_per_page=20
flag_c=0
flag_m=0
dirC=""
dirM=""

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
    local j_loop=$((j * max_per_page))
  fi
  echo "Diretorio atual: $(pwd)"
  echo "$values_len arquivos | pagina ${j}/$((values_len / max_per_page))"
  echo "------------------------------------"
  echo "Mover: ${dirM:-null}"
  echo "Copiar: ${dirC:-null}"
  echo "------------------------------------"
  for ((i = $j_loop; i < ${#values[@]}; i++)); do
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

    if [[ $i -gt $((max_per_page * (j + 1))) ]]; then
      echo '...'
      break
    fi
  done
  echo "------------------------------------"
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
        if [[ $index -lt $((((page + 1) * max_per_page) - max_per_page + 1)) ]]; then
          index=$((((page + 1) * max_per_page) + 1))
          if [[ $index -gt $values_len ]]; then index=$((values_len - 1)); fi
        else
          ((index--))
        fi
      elif [[ $key == 'B' ]]; then
        if [[ $index -gt $(((page + 1) * max_per_page)) || $index -gt $((values_len - 2)) ]]; then
          index=$((((page + 1) * max_per_page) - max_per_page))
        else
          ((index++))
        fi
      elif [[ $key == 'C' && $page -lt $((values_len / max_per_page)) ]]; then
        displayValues $((page++))
        ((index += max_per_page))
        if [[ $index -gt $values_len ]]; then index=$((values_len - 1)); fi
      elif [[ $key == 'D' && $page -gt 0 ]]; then
        displayValues $((page--))
        ((index -= max_per_page))
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
    if [[ -f ${values[$index]} ]]; then
      $editor "$PWD"
    else
      $editor ${values[$index]}
    fi

  elif [[ $key == 'x' && $page -lt $((values_len / max_per_page)) ]]; then
    displayValues $((page++))
    ((index += max_per_page))

  elif [[ $key == 'z' && $page -gt 0 ]]; then
    displayValues $((page--))
    ((index -= max_per_page))

  elif [[ $key == '/' ]]; then
    getValues
    displayValues $page
    search=""
    while true; do
      read -n 1 -p "Pesquisar: $search" char
      if [[ $char == "" ]]; then
        break
      fi
      if [[ $char == $'\x7f' ]]; then
        if [[ ${#search} -eq 1 ]]; then
          break
        fi
        search=${search:0:-1}
        getValues
      else
        search+=$char
      fi
      if [[ $char == $'\e' ]]; then
        getValues
        displayValues $page
        break
      fi
      values=($(echo ${values[@]} | tr ' ' '\n' | grep -i $search))
      values_len=${#values[@]}
      displayValues $page
    done

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

  elif [[ $key == 'c' ]]; then
    if [[ $flag_c == 0 ]]; then
        if [[ -f ${values[$index]} ]]; then
            dirC="${PWD}/${values[$index]}"
            echo "Arquivo ${values[$index]} copiado!"
            flag_c=1
        else
            echo "Diretorio ${values[$index]} copiado!"
            dirC="${PWD}/${values[$index]}"
            flag_c=1
        fi
    else
      if [[ $flag_c == 0 ]]; then
        flag_c=0
        cp $dirC $PWD
        dirC=""
        echo "Arquivo colado!"
        getValues
        displayValues $page
      else
        flag_c=0
        cp -r $dirC $PWD
        dirC=""
        echo "Diretorio colado!"
        getValues
        displayValues $page
      fi
    fi

  elif [[ $key == 'm' ]]; then
    if [[ $flag_m == 0 ]]; then
      dirM="${PWD}/${values[$index]}"
      echo "Arquivo ${values[$index]} recortado!"
      flag_m=1
    else
      flag_m=0
      mv $dirM $PWD
      dirM=""
      echo "Arquivo colado!"
      getValues
      displayValues $page
    fi

  elif [[ $key == 'v' ]]; then
    flag_m=0
    dirC=""
    dirM=""
    flag_c=0
    echo "Colar cancelado!"

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
    echo "c: copiar e colar arquivo/diretorio"
    echo "m: mover e colar arquivo/diretorio"
    echo "v: cancelar copiar/mover"
    echo "h: ajuda"
    read -sn1
    getValues
    displayValues $page
  fi

done
