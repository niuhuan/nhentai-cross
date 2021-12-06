package nhentai

import (
	"encoding/json"
	"github.com/pkg/errors"
	"nhentai/nhentai/constant"
	"nhentai/nhentai/database/cache"
	"nhentai/nhentai/database/properties"
	"path"
)

var cachePath string

func InitNHentai(documentDir string) {
	databaseDir := path.Join(documentDir, "database")
	constant.ObtainDir(databaseDir)
	properties.Init(databaseDir)
	cache.Init(databaseDir)
	cachePath = path.Join(documentDir, "cache")
	constant.ObtainDir(cachePath)
	initClient()
}

func cacheImagePath(aliasPath string) string {
	return path.Join(cachePath, aliasPath)
}

var methods = map[string]func(string) (string, error){
	"availableWebAddresses": availableWebAddresses,
	"availableImgAddresses": availableImgAddresses,
	"setProxy":              setProxy,
	"getProxy":              getProxy,
	"setWebAddress":         setWebAddress,
	"getWebAddress":         getWebAddress,
	"setImgAddress":         setImgAddress,
	"getImgAddress":         getImgAddress,
	"comics":                comics,
	"comicsByTagName":       comicsByTagName,
	"comicsBySearchRaw":     comicsBySearchRaw,
	"comicInfo":             comicInfo,
	"cacheImageByUrlPath":   cacheImageByUrlPath,
	"loadProperty":          loadProperty,
	"saveProperty":          saveProperty,
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
