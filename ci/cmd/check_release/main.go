package main

import (
	"bytes"
	"ci/commons"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

const owner = "niuhuan"
const repo = "nhentai-cross"
const ua = "niuhuan nhentai-cross ci"
const mainBranch = "master"

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
	// get version
	getReleaseRequest, err := http.NewRequest(
		"GET",
		fmt.Sprintf("https://api.github.com/repos/%v/%v/releases/tags/%v", owner, repo, version.Code),
		nil,
	)
	if err != nil {
		panic(nil)
	}
	getReleaseRequest.Header.Set("User-Agent", ua)
	getReleaseRequest.Header.Set("Authorization", ghToken)
	getReleaseResponse, err := http.DefaultClient.Do(getReleaseRequest)
	if err != nil {
		panic(nil)
	}
	defer getReleaseResponse.Body.Close()
	if getReleaseResponse.StatusCode == 404 {
		url := fmt.Sprintf("https://api.github.com/repos/%v/%v/releases", owner, repo)
		body := map[string]interface{}{
			"tag_name":         version.Code,
			"target_commitish": mainBranch,
			"name":             version.Code,
			"body":             version.Info,
		}
		var buff []byte
		buff, err = json.Marshal(&body)
		if err != nil {
			panic(err)
		}
		var createReleaseRequest *http.Request
		createReleaseRequest, err = http.NewRequest("POST", url, bytes.NewBuffer(buff))
		if err != nil {
			panic(nil)
		}
		createReleaseRequest.Header.Set("User-Agent", ua)
		createReleaseRequest.Header.Set("Authorization", ghToken)
		var createReleaseResponse *http.Response
		createReleaseResponse, err = http.DefaultClient.Do(createReleaseRequest)
		if err != nil {
			panic(nil)
		}
		defer createReleaseResponse.Body.Close()
		if createReleaseResponse.StatusCode != 201 {
			buff, err = ioutil.ReadAll(createReleaseResponse.Body)
			if err != nil {
				panic(err)
			}
			println(string(buff))
			panic("NOT 201")
		}
	}
}
