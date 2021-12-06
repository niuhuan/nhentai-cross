package mobile

import (
	"nhentai/nhentai"
)

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
