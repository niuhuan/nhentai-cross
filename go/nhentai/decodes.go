package nhentai

import (
	"errors"
	_ "golang.org/x/image/webp"
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

// 下载图片并decode
func decodeFromUrl(url string) ([]byte, error) {
	m := takeMutex()
	m.Lock()
	defer m.Unlock()
	request, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	buff, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}
	if response.StatusCode != 200 {
		println("NOT 200")
		println(string(buff))
		return nil, errors.New("code is not 200")
	}
	return buff, nil
}

// decodeFromCache 仅下载使用
func decodeFromRemote(url string) ([]byte, error) {
	cache := cache.FindImageCache(url)
	if cache != nil {
		return ioutil.ReadFile(cacheImagePath(cache.LocalPath))
	}
	return nil, errors.New("not found")
}
