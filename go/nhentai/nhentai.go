package nhentai

import (
	"encoding/json"
	"github.com/niuhuan/nhentai-go"
	"github.com/pkg/errors"
	"io/ioutil"
	"nhentai/nhentai/constant"
	"nhentai/nhentai/database/active"
	"nhentai/nhentai/database/cache"
	"nhentai/nhentai/database/properties"
	"path"
	"strconv"
)

var initFlag bool
var cachePath string
var downloadPath string

func InitNHentai(documentDir string) {
	if initFlag {
		return
	}
	initFlag = true
	databaseDir := path.Join(documentDir, "database")
	constant.ObtainDir(databaseDir)
	properties.Init(databaseDir)
	cache.Init(databaseDir)
	active.Init(databaseDir)
	cachePath = path.Join(documentDir, "cache")
	constant.ObtainDir(cachePath)
	downloadPath = path.Join(documentDir, "download")
	constant.ObtainDir(downloadPath)
	initClient()
	go initDownload()
}

func cacheImagePath(aliasPath string) string {
	return path.Join(cachePath, aliasPath)
}

var methods = map[string]func(string) (string, error){
	"availableWebAddresses":      availableWebAddresses,
	"availableImgAddresses":      availableImgAddresses,
	"setProxy":                   setProxy,
	"getProxy":                   getProxy,
	"comics":                     comics,
	"comicsByTagName":            comicsByTagName,
	"comicsBySearchRaw":          comicsBySearchRaw,
	"comicInfo":                  comicInfo,
	"cacheImageByUrlPath":        cacheImageByUrlPath,
	"loadProperty":               loadProperty,
	"saveProperty":               saveProperty,
	"saveViewInfo":               saveViewInfo,
	"saveViewIndex":              saveViewIndex,
	"loadLastViewIndexByComicId": loadLastViewIndexByComicId,
	"downloadComic":              downloadComic,
	"hasDownload":                hasDownload,
	"listDownloadComicInfo":      listDownloadComicInfo,
	"downloadSetDelete":          downloadSetDelete,
	"httpGet":                    httpGet,
	"convertImageToJPEG100":      convertImageToJPEG100,
	"setCookie":                  setCookie,
	"setUserAgent":               setUserAgent,
}

func setUserAgent(s string) (string, error) {
	client.UserAgent = s
	return "", nil
}

func setCookie(s string) (string, error) {
	client.Cookie = s
	return "", nil
}

func FlatInvoke(method string, params string) (string, error) {
	if method, ok := methods[method]; ok {
		return method(params)
	}
	return "", errors.New("method not found (nhentai main)")
}

func saveProperty(params string) (string, error) {
	var paramsStruct struct {
		Name  string `json:"name"`
		Value string `json:"value"`
	}
	json.Unmarshal([]byte(params), &paramsStruct)
	return "", properties.SaveProperty(paramsStruct.Name, paramsStruct.Value)
}

func loadProperty(params string) (string, error) {
	var paramsStruct struct {
		Name         string `json:"name"`
		DefaultValue string `json:"defaultValue"`
	}
	json.Unmarshal([]byte(params), &paramsStruct)
	return properties.LoadProperty(paramsStruct.Name, paramsStruct.DefaultValue)
}

func saveViewInfo(params string) (string, error) {
	var comic nhentai.ComicInfo
	json.Unmarshal([]byte(params), &comic)
	return "", active.SaveViewInfo(comic)
}

func saveViewIndex(params string) (string, error) {
	var paramsStruct struct {
		Info  nhentai.ComicInfo `json:"info"`
		Index int               `json:"index"`
	}
	json.Unmarshal([]byte(params), &paramsStruct)
	return "", active.SaveViewIndex(paramsStruct.Info, paramsStruct.Index)
}

func loadLastViewIndexByComicId(params string) (string, error) {
	comicId, err := strconv.Atoi(params)
	if err != nil {
		return "", err
	}
	return serialize(active.LoadLastViewIndexByComicId(comicId))
}

func downloadComic(params string) (string, error) {
	var comic nhentai.ComicInfo
	json.Unmarshal([]byte(params), &comic)
	return "", active.CreateDownload(comic)
}

func hasDownload(params string) (string, error) {
	comicId, err := strconv.Atoi(params)
	if err != nil {
		return "", err
	}
	return strconv.FormatBool(active.HasDownload(comicId)), nil
}

func listDownloadComicInfo(s string) (string, error) {
	return serialize(active.ListDownloadComicInfo(), nil)
}

func downloadSetDelete(params string) (string, error) {
	comicId, err := strconv.Atoi(params)
	if err != nil {
		return "", err
	}
	active.MarkComicDeleting(comicId)
	downloadRestart = true
	return "", nil
}

func httpGet(url string) (string, error) {
	rsp, err := client.Get(url)
	if err != nil {
		return "", err
	}
	defer rsp.Body.Close()
	buff, err := ioutil.ReadAll(rsp.Body)
	if err != nil {
		return "", err
	}
	return string(buff), nil
}
