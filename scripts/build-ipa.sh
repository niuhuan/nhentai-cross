# 构建未签名的IPA

cd "$( cd "$( dirname "$0"  )" && pwd  )/.."

cd go/mobile
go get golang.org/x/mobile/cmd/gobind
gomobile bind -iosversion 11.0 -target=ios -o lib/Mobile.xcframework ./
cd ../..
flutter build ios --release --no-codesign

cd build
mkdir -p Payload
mv ios/iphoneos/Runner.app Payload

sh ../scripts/thin-payload.sh
zip -9 nosign.ipa -r Payload
