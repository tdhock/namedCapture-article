set -o errexit
R=~/R/R-2.14.0
R=~/R/R-3.5.1
pushd $R
make
popd
$R/bin/R --vanilla < trackDb.test.R > trackDb.test.out
cat trackDb.test.out
$R/bin/R --vanilla < figure-trackDb-test.R
