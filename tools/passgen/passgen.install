#!/bin/bash


# Function to generate random strings
generate_random_string() {
    local length="$1"
    local charset="$2"
    tr -dc "$charset" < /dev/urandom | head -c "$length"
    echo
}


manual() {
# Read user input for string length
read -p "Enter the length of the random string: " length

# Read user input for character types
echo "Select character types:"
echo "1. Letters (a-zA-Z)"
echo "2. Numbers (0-9)"
echo "3. Special characters (@#$%^&*()_+[]{}|;:,.<>?)"
echo "4. Mix of letters, numbers, and special characters"
read -p "Enter your choice (1/2/3/4): " choice

case "$choice" in
    1)
        charset="a-zA-Z"
        ;;
    2)
        charset="0-9"
        ;;
    3)
        charset="\@\#\$%^&*()_+\[\]\{\}\|\;\:,.\<\>?"
        ;;
    4)
        charset="a-zA-Z0-9\@\#\$%^&*()_+\[\]\{\}\|\;\:,.\<\>?"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

while true; do
random_string=$(generate_random_string "$length" "$charset")
printf "\nRandom string: %s\n" "$random_string"
printf "\nPress enter to regenerate:\n"
read ciao
done

}

## Arguments for auto key gen: 1) key length 2) key type 0-4

auto() { 
# Read user input for string length
length="$1"
choice="$2"
case "$choice" in
    1)
        charset="a-zA-Z"
        ;;
    2)
        charset="0-9"
        ;;
    3)
        charset="\@\#\$%^&*()_+\[\]\{\}\|\;\:,.\<\>?"
        ;;
    4)
        charset="a-zA-Z0-9\@\#\$%^&*()_+\[\]\{\}\|\;\:,.\<\>?"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac


random_string=$(generate_random_string "$length" "$charset")
printf "%s\n" "$random_string"

exit 0
}

if [ $# -eq 0 ]; then
manual
else
auto "$1" "$2"
fi

