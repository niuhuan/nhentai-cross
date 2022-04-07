package main

import (
	"ci/commons"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path"
	"strings"
)

const owner = "niuhuan"
const repo = "nhentai-cross"
const ua = "niuhuan nhentai-cross ci"

func main() {
	// get ghToken
	ghToken := os.Getenv("GH_TOKEN")
	if ghToken == "" {
		println("Env ${GH_TOKEN} is not set")
		os.Exit(1)
	}
	// get version
	var version commons.Version
	codeFile, err := ioutil.ReadFile("version.code.txt")
	if err != nil {
		panic(err)
	}
	version.Code = strings.TrimSpace(string(codeFile))
	infoFile, err := ioutil.ReadFile("version.info.txt")
	if err != nil {
		panic(err)
	}
	version.Info = strings.TrimSpace(string(infoFile))
	// get target
	target := os.Getenv("TARGET")
	if ghToken == "" {
		println("Env ${TARGET} is not set")
		os.Exit(1)
	}
	//
	var releaseFilePath string
	var releaseFileName string
	var contentType string
	var contentLength int64
	switch target {
	case "macos":
		releaseFilePath = "build/build.dmg"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-macos-intel.dmg", version.Code)
		contentType = "application/octet-stream"
	case "ios":
		releaseFilePath = "build/nosign.ipa"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-ios-nosign.ipa", version.Code)
		contentType = "application/octet-stream"
	case "windows":
		releaseFilePath = "build/build.zip"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-windows-x86_64.zip", version.Code)
		contentType = "application/octet-stream"
	case "linux":
		releaseFilePath = "build/build.AppImage"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-linux-x86_64.AppImage", version.Code)
		contentType = "application/octet-stream"
	case "android-arm32":
		releaseFilePath = "build/app/outputs/flutter-apk/app-release.apk"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-android-arm32.apk", version.Code)
		contentType = "application/octet-stream"
	case "android-arm64":
		releaseFilePath = "build/app/outputs/flutter-apk/app-release.apk"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-android-arm64.apk", version.Code)
		contentType = "application/octet-stream"
	case "android-x86_64":
		releaseFilePath = "build/app/outputs/flutter-apk/app-release.apk"
		releaseFileName = fmt.Sprintf("nhentai-cross-%v-android-x86_64.apk", version.Code)
		contentType = "application/octet-stream"
	}
	releaseFilePath = path.Join("..", releaseFilePath)
	info, err := os.Stat(releaseFilePath)
	if err != nil {
		panic(err)
	}
	contentLength = info.Size()
	// get version
	getReleaseRequest, err := http.NewRequest(
		"GET",
		fmt.Sprintf("https://api.github.com/repos/%v/%v/releases/tags/%v", owner, repo, version.Code),
		nil,
	)
	if err != nil {
		panic(err)
	}
	getReleaseRequest.Header.Set("User-Agent", ua)
	getReleaseRequest.Header.Set("Authorization", ghToken)
	getReleaseResponse, err := http.DefaultClient.Do(getReleaseRequest)
	if err != nil {
		panic(err)
	}
	defer getReleaseResponse.Body.Close()
	if getReleaseResponse.StatusCode == 404 {
		panic("NOT FOUND RELEASE")
	}
	buff, err := ioutil.ReadAll(getReleaseResponse.Body)
	if err != nil {
		panic(err)
	}
	var release commons.Release
	err = json.Unmarshal(buff, &release)
	if err != nil {
		println(string(buff))
		panic(err)
	}
	file, err := os.Open(releaseFilePath)
	if err != nil {
		panic(err)
	}
	defer file.Close()
	uploadUrl := fmt.Sprintf("https://uploads.github.com/repos/%v/%v/releases/%v/assets?name=%v", owner, repo, release.Id, releaseFileName)
	uploadRequest, err := http.NewRequest("POST", uploadUrl, file)
	if err != nil {
		panic(err)
	}
	uploadRequest.Header.Set("User-Agent", ua)
	uploadRequest.Header.Set("Authorization", ghToken)
	uploadRequest.Header.Set("Content-Type", contentType)
	uploadRequest.ContentLength = contentLength
	uploadResponse, err := http.DefaultClient.Do(uploadRequest)
	if err != nil {
		panic(err)
	}
	if uploadResponse.StatusCode != 201 {
		buff, err = ioutil.ReadAll(uploadResponse.Body)
		if err != nil {
			panic(err)
		}
		println(string(buff))
		panic("NOT 201")
	}
}
