#!/bin/bash

# Functions ==============================================

# return 1 if global command line program installed, else 0
# example
# echo "psql: $(program_is_installed psql)"
function program_is_installed {
    # set to 1 initially
    local return_=1
    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }
    # return value
    echo "$return_"
}

# echo pass or fail
# example
# echo echo_if 1 "Passed"
# echo echo_if 0 "Failed"
function echo_if {
    if [ $1 == 1 ]; then
        echo "+"
    else
        echo "-"
    fi
}

# ============================================== Functions

echo "Detected OS: ${OSTYPE//[0-9.]}"

echo "Checking required apps..."
# os independent utils
echo "psql           $(echo_if $(program_is_installed psql))"
echo "perl           $(echo_if $(program_is_installed perl))"
echo "tsort          $(echo_if $(program_is_installed tsort))"
echo "hg             $(echo_if $(program_is_installed hg))"
echo "git            $(echo_if $(program_is_installed git))"

# os dependent utils
if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
    echo "gsed           $(echo_if $(program_is_installed gsed))"
    echo "ggrep          $(echo_if $(program_is_installed ggrep))"
else
    echo "sed            $(echo_if $(program_is_installed sed))"
    echo "grep           $(echo_if $(program_is_installed grep))"
fi
