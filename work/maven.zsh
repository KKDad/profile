# For dealing with Maven
###############################################################
function getVersion() {
  local verbose=$1
  if [[ "$verbose" == "-v" ]]; then
    echo "mvn org.apache.maven.plugins:maven-help-plugin:3.4.1:evaluate -Dexpression=project.version"
    mvn org.apache.maven.plugins:maven-help-plugin:3.4.1:evaluate -Dexpression=project.version
  else
    echo "mvn org.apache.maven.plugins:maven-help-plugin:3.4.1:evaluate -Dexpression=project.version | grep -v '[INFO]'"
    mvn org.apache.maven.plugins:maven-help-plugin:3.4.1:evaluate -Dexpression=project.version | grep -v '[INFO]'
  fi
}

function setVersion() {
  local v=$1
  cat pom.xml | mvn org.codehaus.mojo:versions-maven-plugin:2.17.1:set -DgenerateBackupPoms=false -DprocessAllModules -DnewVersion=${v}
}
alias fastinstall='mvn clean install -DskipTests=True -Dskip.unit.tests=True -Dskip.integration.tests=True -Dspotbugs.skip -Dassembly.skipAssembly=true -T 10'
