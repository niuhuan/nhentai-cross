package main

import (
	"errors"
	"nhentai/nhentai"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strings"
)

func init() {
	nhentai.InitNHentai(documentPath())
}

func documentPath() string {
	applicationDir, err := os.UserHomeDir()
	if err != nil {
		panic(err)
	}
	switch runtime.GOOS {
	case "windows":
		// applicationDir = winDocumentPath.Join(applicationDir, "AppData", "Roaming", "nhentai")
		file, err := exec.LookPath(os.Args[0])
		if err != nil {
			panic(err)
		}
		winDocumentPath, err := filepath.Abs(file)
		if err != nil {
			panic(err)
		}
		i := strings.LastIndex(winDocumentPath, "/")
		if i < 0 {
			i = strings.LastIndex(winDocumentPath, "\\")
		}
		if i < 0 {
			panic(errors.New(" can't find \"/\" or \"\\\""))
		}
		applicationDir = path.Join(winDocumentPath[0:i+1], "data")
	case "darwin":
		applicationDir = path.Join(applicationDir, "Library", "Application Support", "nhentai")
	case "linux":
		applicationDir = path.Join(applicationDir, ".nhentai")
	default:
		panic(errors.New("not supported system"))
	}
	if _, err = os.Stat(applicationDir); err != nil {
		if os.IsNotExist(err) {
			err = os.MkdirAll(applicationDir, os.FileMode(0700))
			if err != nil {
				panic(err)
			}
		} else {
			panic(err)
		}
	}
	return applicationDir
}
