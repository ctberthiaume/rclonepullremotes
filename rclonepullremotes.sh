#!/bin/sh
#
# Copy rclone remotes to local destination. Remotes to copy are listed in a
# text file, one remote per line, without the trailing ":".
#
VERSION=0.1.6

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

show_help() {
  echo "$(basename $0) [-c rclone_config] [-m modify-window] [-h] remotes_file destination"
  echo "$VERSION"
}

remotesfile=
dest=
configfile=""
modifywindow=""

while :; do
  case $1 in
    -h|-\?|--help)
      show_help
      exit
      ;;
    -c|--config)
      if [ "$2" ]; then
        configfile=$2
        shift
      else
        die 'ERROR: "--config" requires a non-empty option argument'
      fi
      ;;
    --config=?*)
      configfile=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --config=)         # Handle the case of an empty --config=
      die 'ERROR: "--config" requires a non-empty option argument'
      ;;
    -m|--modify-window)
      if [ "$2" ]; then
        modifywindow=$2
        shift
      else
        die 'ERROR: "--modify-window" requires a non-empty option argument'
      fi
      ;;
    --modify-window=?*)
      modifywindow=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --modify-window=)         # Handle the case of an empty --modify-window=
      die 'ERROR: "--modify-window" requires a non-empty option argument'
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

rcloneargs=(copy -v --stats 30m --drive-acknowledge-abuse)
if [ -n "$configfile" ]; then
  rcloneargs+=("--config=$configfile")
fi
if [ -n "$modifywindow" ]; then
  rcloneargs+=("--modify-window=$modifywindow")
fi

echo "-----------------------------------------------------------------------------"
echo "BEGIN"
echo "$0 $*"
echo "version $VERSION"
date
echo "-----------------------------------------------------------------------------"
while IFS= read -r remote
do
  if [ -n "$remote" ]; then
    printf "copying remote %s: to %s\n" "$remote" "$dest"
    /usr/local/bin/rclone "${rcloneargs[@]}" "${remote}:" "$dest/${remote}" 2>&1
  fi
done < "$remotesfile"
echo "-----------------------------------------------------------------------------"
echo "END"
date
echo "-----------------------------------------------------------------------------\n"
