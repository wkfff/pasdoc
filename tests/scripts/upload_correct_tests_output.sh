#!/bin/bash
set -eu

# Always run this script with current directory set to
# directory where this script is,
# i.e. tests/scripts/ inside pasdoc sources.
#
# This script uploads to
# [http://pasdoc.sourceforge.net/correct_tests_output/]
# current output of tests generated in ../ .
# This means that you're accepting current output of tests
# (for some output formats) as "correct".
#
# Options "$2" and following are the names of output formats
# (as for pasdoc's --format option), these say which subdirectory
# of ../tests/ should be uploaded.
#
# Option "$1" is your username on sourceforge.
# Note that you will be asked (more than once) for your password
# unless you configured your ssh keys, which is recommended.
#
# After uploading it calls ./download_correct_tests_output.sh
# for every uploaded output.
# This way it checks that files were correctly uploaded
# and also sets your local version of ../correct_output/ directory
# to the correct state.
# So after calling this script successfully, directories
# ../$2/ and ../correct_output/$2/ are always equal.
# (and ../$3/ and ../correct_output/$3/, and so on).
#
# Precisely what files are uploaded for each format $FORMAT:
# - $FORMAT.tar.gz -- archived contents of ../$FORMAT/
#   Easily downloadable, e.g. by download_correct_tests_output.
# - $FORMAT directory -- copy of ../$FORMAT/
#   Easy to browse, so we can e.g. make links from pasdoc's wiki
#   page ProjectsUsingPasDoc to this.
# - $FORMAT.timestamp -- current date/time, your username (taken from $1)
#   to make this information easy available.
#   (to be able to always answer the question "who and when uploaded this ?")
#
# Note: after uploading, it sets group of uploaded files
# to `pasdoc' and makes them writeable by the group.
# This is done in order to allow other pasdoc developers
# to also execute this script, overriding files uploaded by you.
#
# Requisites: `scp' command, `ssh' command.

# Parse options
SF_USERNAME="$1"
shift 1

upload_one_format ()
{
  # Parse options
  FORMAT="$1"
  shift 1

  # Prepare clean TEMP_PATH
  TEMP_PATH=upload_correct_tests_output_tmp/
  rm -Rf "$TEMP_PATH"
  mkdir "$TEMP_PATH"

  # Prepare tar.gz archive
  ARCHIVE_FILENAME_NONDIR="$FORMAT.tar.gz"
  ARCHIVE_FILENAME="$TEMP_PATH""$ARCHIVE_FILENAME_NONDIR"
  echo "Creating $ARCHIVE_FILENAME_NONDIR ..."
  # Note: We temporary jump to ../, this way we can pack files using
  # "$FORMAT"/ instead of ../"$FORMAT"/. Some tar versions would
  # strip "../" automatically, but some would not.
  cd ../
  tar czf scripts/"$ARCHIVE_FILENAME" "$FORMAT"/
  cd scripts/

  # Prepare timestamp file
  TIMESTAMP_FILENAME_NONDIR="$FORMAT.timestamp"
  TIMESTAMP_FILENAME="$TEMP_PATH""$TIMESTAMP_FILENAME_NONDIR"
  echo "Creating $TIMESTAMP_FILENAME_NONDIR ..."
  date '+%F %T' > "$TIMESTAMP_FILENAME"
  echo "$SF_USERNAME" >> "$TIMESTAMP_FILENAME"

  # Do the actual uploading to the server

  echo "Uploading ..."

  SF_PATH=/home/groups/p/pa/pasdoc/htdocs/correct_tests_output/
  SF_CONNECT="$SF_USERNAME",pasdoc@web.sourceforge.net:"$SF_PATH"

  scp "$ARCHIVE_FILENAME" "$TIMESTAMP_FILENAME" "$SF_CONNECT"

  # I could do here simple
  #   scp -r ../"$FORMAT"/ "$SF_CONNECT"
  # but this requires uploading all files unpacked.
  # It's much quickier to just log to server and untar there uploaded archive.
  #
  # After uploading, I change permission of uploaded and unpacked
  # files so that they are writeable by pasdoc group
  # (which means pasdoc developers).
  # Note that I don't do here simple
  #   ./ssh_chmod_writeable_by_pasdoc.sh "$SF_USERNAME" "$SF_PATH"
  # because I can chmod only the files that "$SF_USERNAME" owns
  # (so I chmod only the files that I uploaded).
  #
  # 2008-09-19 Kambi notes: interactive shell access is for now
  # turned off on SourceForge, (documented
  # http://sourceforge.net/community/forum/topic.php?id=2838&page ).
  # So following doesn't work
  # (server answers "This is a restricted Shell Account
  # You cannot execute anything here.").
  # Possibly files will be forced to have correct group (that's the idea
  # behind username "xxx,pasdoc" after all), but I don't know
  # what permissions they will have.
  # TODO: check and eventually fix (chmod locally and uploading by rsync
  # should help to set the right permissions?)

#   ssh -l "$SF_USERNAME",pasdoc web.sourceforge.net <<EOF
#   cd "$SF_PATH"
#   tar xzf "$ARCHIVE_FILENAME_NONDIR"
#   chgrp -R pasdoc "$TIMESTAMP_FILENAME_NONDIR" "$ARCHIVE_FILENAME_NONDIR" "$FORMAT"/
#   chmod -R g+w    "$TIMESTAMP_FILENAME_NONDIR" "$ARCHIVE_FILENAME_NONDIR" "$FORMAT"/
# EOF

  # Clean temp dir
  rm -Rf upload_correct_tests_output_tmp/

  ./download_correct_tests_output.sh "$FORMAT"
}

for FORMAT; do
  upload_one_format "$FORMAT"
done