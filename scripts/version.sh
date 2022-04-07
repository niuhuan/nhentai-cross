# 设置版本号

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

if [ "$1" == "set" ] ; then
  if [ "$2" != "" ] ; then
    echo $2 > lib/assets/version.txt
  fi

elif [ "$1" == "unset" ]; then
    rm -f lib/assets/version.txt
fi
