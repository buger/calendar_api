#!/bin/bash

#
# usage: 
#   sh perf/stats.sh search_events_perf_spec.rb 2648888 f2eefba
#                    ^                          ^       ^
#                    performance spec file      start   end
#

set -e

spec=`basename $1 .rb`
spec_csv="perf/csv/$spec.csv"
start=$2
end=$3

if [ -e $spec_csv ]; then
  rm $spec_csv
fi

time_perf_spec() {
  echo `bundle exec "rspec perf/$spec.rb" | grep '^RUNTIME: ' | awk '{print $2}'`
}

revs=`git rev-list --reverse ${start}..${end}`

for rev in $revs; do
  git checkout --quiet $rev
  echo "$rev,`time_perf_spec`" >> $spec_csv
  git reset --hard
done

