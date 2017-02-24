#!/bin/bash

# Simple tool to list dependencies in form suitable for tsort utility.
# Run this script like this:
# /some/path/list-dependencies-from-patches.sh *.sql | tsort | sed '1!G;h;$!d'
# To get patches in order that satisfies dependencies while loading them.

function sed_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        gsed "$@"
    else
        sed "$@"
    fi
}

function grep_bin() {
    if [[ ${OSTYPE//[0-9.]} == "solaris" ]]; then
        ggrep "$@"
    else
        grep "$@"
    fi
}


grep_bin -hiE '^[[:space:]]*vt_patch_name CONSTANT|^[[:space:]]*va_depend_on[[:space:]]*TEXT\[\]' "$@" \
    | sed_bin 's/^.*:=\s//' \
    | while read LINE
      do
          if [[ $LINE != ARRAY* ]]; then
              export PATCH_NAME="$( echo "$LINE" | cut -d\' -f2 )"
          else
              echo "$LINE" | sed_bin 's/::TEXT\[\];//' | \
              perl -ne '
                my @w;
                if ( s/^ARRAY\s*\[// ) {
                    s/\].*//;
                    @w = /\047([^\047]+)\047/g;
                }
                push @w, $ENV{"PATCH_NAME"} if ( 0 == @w ) || ( 0 == ( @w % 2 ) );
                printf "%s %s\n", $ENV{"PATCH_NAME"}, $_ for @w;
            '
          fi
      done
