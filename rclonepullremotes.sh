#!/bin/sh
#
# Copy rclone remotes to local destination. Remotes to copy are listed in a
# text file, one remote per line, without the trailing ":".


die() {
  printf '%s\n' "$1" >&2
  exit 1
}

show_help() {
  echo "$(basename $0) [-c rclone_config] [-h] remotes_file destination"
}

remotesfile=
dest=
config=

while :; do
  case $1 in
    -h|-\?|--help)
      show_help
      exit
      ;;
    -c|--config)
      if [ "$2" ]; then
        config=$2
        shift
      else
        die 'ERROR: "--config" requires a non-empty option argument'
      fi
      ;;
    --config=?*)
      config=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --config=)         # Handle the case of an empty --config=
      die 'ERROR: "--config" requires a non-empty option argument'
      ;;
    --)  # End of all options.
      shift
      break
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *)
      break
  esac
  shift
done

if [ -z "$1" ]; then
  die 'ERROR: "remotes_file" argument is required'
fi
if [ -z "$2" ]; then
  die 'ERROR: "destination" argument is required'
fi

if [ ! -f "$1" ]
then
  die 'ERROR: "remotes_file" is not a file or does not exist'
fi

remotesfile=$1
dest=$2

while IFS= read -r remote
do
  if [ -n "$remote" ]; then
    printf "\ncopying remote %s: to %s\n" "$remote" "$dest"
    if [ -z "$config" ]; then
      /usr/local/bin/rclone copy -v --drive-acknowledge-abuse "${remote}:" "$dest/${remote}"
    else
      /usr/local/bin/rclone copy -v --drive-acknowledge-abuse --config "$config" "${remote}:" "$dest/${remote}"
    fi
  fi
done < "$remotesfile"
