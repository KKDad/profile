# JDK switching: macOS asks java_home, Ubuntu uses the apt-installed OpenJDKs.
java_use() {
  local version=$1
  if [ -x /usr/libexec/java_home ]; then
    export JAVA_HOME=$(/usr/libexec/java_home -v "$version")
  else
    export JAVA_HOME="/usr/lib/jvm/java-${version}-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
  echo "JAVA_HOME set to $JAVA_HOME"
}

java17() { java_use 17; }
java21() { java_use 21; }
java25() { java_use 25; }
