package nhentai


import (
"bytes"
"errors"
_ "golang.org/x/image/webp"
"image"
_ "image/gif"
_ "image/jpeg"
_ "image/png"
"io/ioutil"
"net/http"
	"nhentai/nhentai/database/cache"
	"sync"
)

var mutexCounter = -1
var busMutex *sync.Mutex
var subMutexes []*sync.Mutex

func init() {
	busMutex = &sync.Mutex{}
	for i := 0; i < 5; i++ {
		subMutexes = append(subMutexes, &sync.Mutex{})
	}
}

// takeMutex 下载图片获取一个锁, 这样只能同时下载5张图片
func takeMutex() *sync.Mutex {
	busMutex.Lock()
	defer busMutex.Unlock()
	mutexCounter = (mutexCounter + 1) % len(subMutexes)
	return subMutexes[mutexCounter]
}

func decodeInfoFromBuff(buff []byte) (image.Image, string, error) {
	buffer := bytes.NewBuffer(buff)
	return image.Decode(buffer)
}

func decodeFromFile(path string) ([]byte, image.Image, string, error) {
	b, e := ioutil.ReadFile(path)
	if e != nil {
		return nil, nil, "", e
	}
	i, f, e := decodeInfoFromBuff(b)
	if e != nil {
		return nil, nil, "", e
	}
	return b, i, f, e
}

// 下载图片并decode
func decodeFromUrl(url string) ([]byte, image.Image, string, error) {
	m := takeMutex()
	m.Lock()
	defer m.Unlock()
	request, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, nil, "", err
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, nil, "", err
	}
	defer response.Body.Close()
	if response.StatusCode != 200 {
		return nil, nil, "", errors.New("code is not 200")
	}
	buff, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return nil, nil, "", err
	}
	img, format, err := decodeInfoFromBuff(buff)
	if err != nil {
		return nil, nil, "", err
	}
	return buff, img, format, err
}

// decodeFromCache 仅下载使用
func decodeFromRemote(url string) ([]byte, image.Image, string, error) {
	cache := cache.FindImageCache(url)
	if cache != nil {
		buff, err := ioutil.ReadFile(cacheImagePath(cache.LocalPath))
		if err != nil {
			return nil, nil, "", err
		}
		img, format, err := decodeInfoFromBuff(buff)
		if err != nil {
			return nil, nil, "", err
		}
		return buff, img, format, err
	}
	return nil, nil, "", errors.New("not found")
}

