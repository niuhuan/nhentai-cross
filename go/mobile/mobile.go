package mobile

import (
	"errors"
	"nhentai/nhentai"
	"nhentai/nhentai/constant"
	"os"
	"path"
)

func Migration(source, target string) {
	constant.ObtainDir(source)
	constant.ObtainDir(target)
	cacheDIr := path.Join(source, "cache")
	downloadDir := path.Join(source, "download")
	databaseDir := path.Join(source, "database")

	cacheE, _ := exists(cacheDIr)
	downloadE, _ := exists(downloadDir)
	databaseE, _ := exists(databaseDir)

	if cacheE {
		os.Rename(cacheDIr, path.Join(target, "cache"))
	}

	if downloadE {
		os.Rename(downloadDir, path.Join(target, "download"))
	}

	if databaseE {
		os.Rename(databaseDir, path.Join(target, "database"))
	}

}

func exists(name string) (bool, error) {
	_, err := os.Stat(name)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}

func InitApplication(application string) {
	nhentai.InitNHentai(application)
}

func FlatInvoke(method string, params string) (string, error) {
	return nhentai.FlatInvoke(method, params)
}

func EventNotify(notify EventNotifyHandler) {
	// controller.EventNotify = notify.OnNotify
}

type EventNotifyHandler interface {
	OnNotify(message string)
}
