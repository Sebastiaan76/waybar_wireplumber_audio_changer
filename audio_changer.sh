#!/bin/bash
# Function to parse and extract sinks from wpctl status output
parse_wpctl_status() {
    # Extract sinks information block using awk, stop after the first "Sources" block
    sinks_block=$(wpctl status | awk '/ ├─ Sinks:/{flag=1; next} / ├─ Sources:/{flag=0} flag' |
        sed 's/│//g' |
        sed '/^[[:space:]]*$/d' |
        sed 's/\[vol: [^]]*\]//g' |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/[[:space:]]\+/ /g')

    # Process each line within the sinks block
    echo "$sinks_block" | while IFS= read -r line; do
        # Check if this sink is the default (marked with an asterisk)
        if [[ "$line" == *"*"* ]]; then
            substring=$(echo "$line" | cut -c3-)
            echo "<b>$substring - Default</b>"
        else
            echo "$line"
        fi
    done
}
# Collect and format sink information to display in wofi
output=$(parse_wpctl_status)
line_count=$(echo "$output" | wc -l | awk '{print $1 + 1}')

# Call wofi to display the sink list and capture the selected sink
selected_sink=$(echo -e "$output" | wofi --show=dmenu --hide-scroll --allow-markup --define=hide_search=true --location=top_right --width=600 --line=$line_count --xoffset=-60)

# Process user selection from wofi and set the selected sink as default
if [[ -n "$selected_sink" ]]; then
    # Extract the sink name from the selection, removing any HTML markup
    selected_sink_name=$(echo "$selected_sink" | sed -e 's/<[^>]*>//g' -e 's/ - Default//')
    # Find the sink ID corresponding to the selected sink name
    sink_id=$(echo "$selected_sink_name" | grep -Eo '^[0-9]+'| tr -d '\n')
    # Set the default sink using wpctl
    wpctl set-default "$sink_id"
else
    echo "User cancelled the operation."
fi

