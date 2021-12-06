package main

import (
	"errors"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
	"nhentai/nhentai"
	"nhentai/nhentai/database/properties"
	"strconv"
)

type Plugin struct {
}

func (p *Plugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	channel := plugin.NewMethodChannel(messenger, "nhentai", plugin.StandardMethodCodec{})
	channel.HandleFunc("flatInvoke", func(arguments interface{}) (interface{}, error) {
		if argumentsMap, ok := arguments.(map[interface{}]interface{}); ok {
			if method, ok := argumentsMap["method"].(string); ok {
				if params, ok := argumentsMap["params"].(string); ok {
					return nhentai.FlatInvoke(method, params)
				}
			}
		}
		return "", errors.New("method not found (nhentai channel)")
	})
	return nil
}

func (p *Plugin) InitPluginGLFW(window *glfw.Window) error {
	window.SetSizeCallback(func(w *glfw.Window, width int, height int) {
		go func() {
			properties.SaveProperty("window_width", strconv.Itoa(width))
			properties.SaveProperty("window_height", strconv.Itoa(height))
		}()
	})
	window.SetMaximizeCallback(func(w *glfw.Window, iconified bool) {
		go func() {
			properties.SaveProperty("full_screen", strconv.FormatBool(iconified))
		}()
	})
	return nil
}
