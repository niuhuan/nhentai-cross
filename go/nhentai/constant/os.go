package constant

import (
	"os"
	"strings"
)

func ObtainDir(dir string) {
	if _, err := os.Stat(dir); err != nil {
		if os.IsNotExist(err) {
			err = os.MkdirAll(dir, CreateDirMode)
			if err != nil {
				panic(err)
			}
		} else {
			panic(err)
		}
	}
}

func ReasonableFileName(title string) string {
	title = strings.ReplaceAll(title, "\\", "_")
	title = strings.ReplaceAll(title, "/", "_")
	title = strings.ReplaceAll(title, "*", "_")
	title = strings.ReplaceAll(title, "?", "_")
	title = strings.ReplaceAll(title, "<", "_")
	title = strings.ReplaceAll(title, ">", "_")
	title = strings.ReplaceAll(title, "|", "_")
	return title
}
