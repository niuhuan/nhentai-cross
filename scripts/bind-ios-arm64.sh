# 编译所有架构的依赖

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

cd go/mobile

gomobile bind -androidapi 19 -target=ios -o lib/Mobile.xcframework ./
