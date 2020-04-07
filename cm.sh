#!/bin/bash

CONFIGDIR="$HOME/.config/cm"
CONFIGFILE="$CONFIGDIR/config.conf"
THEMEFILE="$CONFIGDIR/theme"

setnames=()
declare -A outfile
declare -A infiles

function parse_config {
    while read line
    do
        if [[ $line =~ "#" ]]
        then
            continue
        fi

        if [[ $line =~ ";" ]]
        then
            local setname=$(echo "$line" | cut -d ';' -f 1)
            local outf=$(echo "$line" | cut -d ';' -f 2)
            local inf=$(echo "$line" | awk -F';' '{ for (i=3; i<=NF; i++) printf("%s ",$i) }')

            setnames+=("$setname")
            outfile[$setname]="$outf"
            infiles[$setname]="$inf"
        fi
    done < $CONFIGFILE
}

function add_set {
    # add_set setname outfile infile1 infile2...
    if [[ $# -lt 3 ]]
    then
        echo "Error: missing arguments."
        echo "Usage: "
        echo -e "\t-a|--add <setname> <outfile> <infiles...>    Add new config set"
        return
    fi

    if [[ "${setnames[@]}" =~ "$1" ]]
    then
        delete_set $1
    fi

    local setline="$1"
    for i in ${@:2}
    do
        local file=$(readlink -f ${i})
        setline+=";${file}"
    done
    echo "$setline" >> $CONFIGFILE
}

function delete_set {
    # delete_set setname
    if [[ $# -lt 1 ]]
    then
        echo "Error: missing arguments."
        echo "Usage: "
        echo -e "\t-d|--delete <setname>                        Delete a config set"
        return
    fi

    sed -n -i "/$1;/!p" $CONFIGFILE
}

function list_sets {
    for i in ${setnames[@]}
    do
        echo "$i:"
        echo -e "\toutfile: ${outfile[$i]}"
        echo -e "\tinfiles: ${infiles[$i]}"
    done
}

function list_themes {
    for f in "$CONFIGDIR/themes"/*
    do
        echo $(basename "$f")
    done
}

function set_theme {
    # set_theme <themename>
    if [[ $# -lt 1 ]]
    then
        echo "Error: missing arguments."
        echo "Usage: "
        echo -e "\t-st|--set-theme <themename>                  Set new active theme"
        return
    fi

    if [[ -f "$CONFIGDIR/themes/$1" ]]
    then
        ln -sf "$CONFIGDIR/themes/$1" "$CONFIGDIR/theme"
    else
        echo "Theme $1 not available."
    fi
}

function reconfigure {
    for i in ${setnames[*]}
    do
        echo "Concatting $i"
        cat ${infiles[$i]} > "${outfile[$i]}"
    done

    echo "Substituting theme"
    awk '(NF && $1 !~ "^[!#]") {\
        gsub("^\\*\\.", "", $1);\
        gsub(":$", "", $1);\
        gsub("\x27", "", $2);\
        printf("%s:%s\n", $1, $2) }' "$THEMEFILE" | while read -r line
    do
        local var=$(echo "$line" | cut -d ':' -f 1)
        local val=$(echo "$line" | cut -d ':' -f 2)

        for i in ${setnames[*]}
        do
            sed -i "s/\${$var}/$val/g" "${outfile[$i]}"
        done
    done
}

function edit {
    # Open editor with config infile
    if [[ $# -lt 1 ]]
    then
        if [[ -x "$(command -v fzf)" ]]
        then
            inf=$(printf '%s\n' "${infiles[@]}" | sed 's/ $//' | fzf)
        else
            echo "Error: missing arguments."
            echo "Usage: "
            echo -e "\t-e|--edit                                    Open a config set using nvim"
        fi
    elif [[ $# -lt 2 ]]
    then
        local inf=$(echo "${infiles[$1]}" | cut -d ' ' -f 1)
    else
        local inf=$(echo "${infiles[$1]}" | cut -d ' ' -f $2)
    fi

    if [[ ! -z "$inf" ]]
    then
        nvim "$inf"
    fi
}

parse_config

# Parse arguments
case "$1" in
    -l|--list-sets)
        list_sets
        ;;
    -a|--add)
        shift
        add_set $@
        ;;
    -d|--delete)
        delete_set $2
        ;;
    -r|--reconfigure)
        reconfigure
        ;;
    -e|--edit)
        shift
        edit $@
        ;;
    -lt|--list-themes)
        list_themes
        ;;
    -st|--set-theme)
        set_theme $2
        ;;
    *)
        echo "Usage: $0 [option] [arguments]"
        echo -e "\t-l |--list                                   List all config sets"
        echo -e "\t-a |--add <setname> <outfile> <infiles...>   Add new config set"
        echo -e "\t-d |--delete <setname>                       Delete a config set"
        echo -e "\t-r |--reconfigure                            Reconfigure all sets"
        echo -e "\t-e |--edit                                   Open a config set using nvim"
        echo -e "\t-lt|--list-themes                            List all available themes"
        echo -e "\t-st|--set-theme <themename>                  Set new active theme"
esac
