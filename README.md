# ConfigManager (cm)
This script is a cleaner bash alternative to rtk (https://github.com/Linouth/rtk)

```
Usage: cm.sh [option] [arguments]
	-l |--list                                   List all config sets
	-a |--add <setname> <outfile> <infiles...>   Add new config set
	-d |--delete <setname>                       Delete a config set
	-r |--reconfigure                            Reconfigure all sets
	-e |--edit                                   Open a config set using nvim
	-lt|--list-themes                            List all available themes
	-st|--set-theme <themename>                  Set new active theme
```

Themes can have the provided yaml format, or standard .Xresources format, or anything matching the following AWK script:
 ```
awk '(NF && $1 !~ "^[!#]") {\
    gsub("^\\*\\.", "", $1);\
    gsub(":$", "", $1);\
    gsub("\x27", "", $2);\
    printf("%s:%s\n", $1, $2) }' "$THEMEFILE"
```
