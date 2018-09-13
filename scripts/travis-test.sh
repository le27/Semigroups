# If a command fails, exit this script with an error code
set -e
set -o pipefail

cd ../..

# Remember some important locations
GAP_DIR=`pwd`
SEMI_DIR="$GAP_DIR/pkg/semigroups"
GAP="$GAP_DIR/bin/gap.sh"
# Create the testlog and remember its location
touch $GAP_DIR/testlog.txt
TESTLOG="`pwd`/testlog.txt"

if [ "$SUITE" == "lint" ]; then

  echo -e "\nLinting with gaplint and cpplint..."
  cd $SEMI_DIR
  gaplint `grep "^\s\+gaplint" Makefile.am | cut -d " " -f2-`
  cpplint --extensions=c,cc,h `grep "^\s\+cpplint" Makefile.am | cut -d " " -f2-`

elif [ "$SUITE" == "coverage" ]; then

  echo -e "\nPerforming code coverage tests..."
  for TEST in $SEMI_DIR/tst/standard/*.tst; do
    FILENAME=${TEST##*/}
    if [ ! `grep -E "$FILENAME" .covignore` ]; then
      $SEMI_DIR/scripts/travis-coverage.py $TEST $THRESHOLD | tee -a $TESTLOG
    else
      echo -e "\033[35mignoring $FILENAME, which is listed in .covignore\033[0m"
    fi
  done
elif [ "$SUITE" == "test" ]; then

  cd $SEMI_DIR/tst/workspaces
  echo -e "\nRunning SaveWorkspace tests..."
  echo "LoadPackage(\"semigroups\"); SemigroupsTestInstall(); Test(\"save-workspace.tst\"); quit; quit; quit;" |
    $GAP -A -r -m 1g -T 2>&1 | tee -a $TESTLOG
  echo -e "\nRunning LoadWorkspace tests..."
  echo "Test(\"load-workspace.tst\"); SemigroupsTestInstall(); quit; quit; quit;" |
    $GAP -L test-output.w -A -x 80 -r -m 1g -T 2>&1 | tee -a $TESTLOG

  echo -e "\nRunning Semigroups package standard tests and manual examples..."
  echo "LoadPackage(\"semigroups\"); SemigroupsTestStandard(); SEMIGROUPS.TestManualExamples();" |
    $GAP -A -x 80 -r -m 1g -T 2>&1 | tee -a $TESTLOG

  # Run GAP tests, but only in 64-bit, since they're far too slow in 32-bit
  if [ "$ABI" == "64" ]; then
    echo -e "\nRunning GAP's testinstall tests with Semigroups loaded..."
    echo "LoadPackage(\"semigroups\"); Read(\"$GAP_DIR/tst/testinstall.g\");" |
      $GAP -A -x 80 -r -m 100m -o 1g -K 2g -T 2>&1 | tee -a $TESTLOG

    #echo -e "\nRunning GAP's testbugfix tests with Semigroups loaded..."
    #echo "LoadPackage(\"semigroups\"); Read(\"$GAP_DIR/tst/testbugfix.g\");" |
    #  $GAP -A -x 80 -r -m 100m -o 1g -K 2g -T 2>&1 | tee -a $TESTLOG
  fi
else
  echo -e "\nUnrecognised test suite"
  exit 1
fi

( ! grep -E "Diff|brk>|#E|Error|Errors detected|# WARNING|fail|Syntax warning|Couldn't open saved workspace|insufficient|WARNING in|FAILED|Total errors found:" $TESTLOG )
