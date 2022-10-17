package nhentai

import (
	"bytes"
	"encoding/json"
	"image"
	"image/jpeg"
	"io/ioutil"
	"nhentai/nhentai/database/cache"
	"os"
	"path"
	"time"
)

// PING

// @
// "104.27.195.88:443"

// t.nhentai.net
//185.177.127.78 (3115417422)
//185.177.127.77 (3115417421)
//23.237.126.122 (401440378)

// t5.nhentai.net
// 185.177.127.77 (3115417421)

// i.nhentai.net
//185.177.127.78 (3115417422)
//23.237.126.122 (401440378)
//185.177.127.77 (3115417421)

func availableWebAddresses(_ string) (string, error) {
	return serialize([]string{
		"104.21.66.123:443",
		"172.67.159.231:443",
	}, nil)
}

func availableImgAddresses(_ string) (string, error) {
	return serialize([]string{
		"185.107.44.3:443",
		"185.177.127.78:443",
		"185.177.127.77:443",
	}, nil)
}

func cacheable(key string, expire time.Duration, reload func() (interface{}, error)) (string, error) {
	// CACHE
	cacheable, err := cache.LoadCache(key, expire)
	if err != nil {
		return "", err
	}
	if cacheable != "" {
		return cacheable, nil
	}
	// RELOAD
	cacheable, err = serialize(reload())
	if err != nil {
		return "", err
	}
	// push to cache (if cache error )
	_ = cache.SaveCache(key, cacheable)
	// return
	return cacheable, nil
}

// 将interface序列化成字符串, 方便与flutter通信
func serialize(point interface{}, err error) (string, error) {
	if err != nil {
		return "", err
	}
	buff, err := json.Marshal(point)
	return string(buff), nil
}

func convertImageToJPEG100(params string) (string, error) {
	var paramsStruct struct {
		Path string `json:"path"`
		Dir  string `json:"dir"`
	}
	err := json.Unmarshal([]byte(params), &paramsStruct)
	if err != nil {
		return "", err
	}
	buff, err := ioutil.ReadFile(paramsStruct.Path)
	if err != nil {
		return "", err
	}
	reader := bytes.NewReader(buff)
	i, _, err := image.Decode(reader)
	if err != nil {
		return "", err
	}
	to := path.Join(paramsStruct.Dir, path.Base(paramsStruct.Path)+".jpg")
	stream, err := os.Create(to)
	if err != nil {
		return "", err
	}
	defer stream.Close()
	return "", jpeg.Encode(stream, i, &jpeg.Options{Quality: 100})
}
