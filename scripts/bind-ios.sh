# 编译所有架构的依赖

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

cd go/mobile

gomobile bind -iosversion 11.0 -target=ios -o lib/Mobile.xcframework ./
