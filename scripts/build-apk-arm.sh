# 仅构建arm的APK

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

cd go/mobile
go get golang.org/x/mobile/cmd/gobind
gomobile bind -androidapi 19 -target=android/arm -o lib/Mobile.aar ./
cd ../..
flutter build apk --target-platform android-arm
