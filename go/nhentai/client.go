package nhentai

import (
	"crypto/md5"
	"encoding/json"
	"fmt"
	source "github.com/niuhuan/nhentai-go"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"nhentai/nhentai/database/active"
	"nhentai/nhentai/database/cache"
	"nhentai/nhentai/database/properties"
	"os"
	"path"
	"strconv"
	"time"
)

var dialer = &net.Dialer{
	Timeout:   30 * time.Second,
	KeepAlive: 30 * time.Second,
}

var client = &source.Client{
	Client: http.Client{
		Transport: &http.Transport{
			Proxy:                 nil,
			TLSHandshakeTimeout:   time.Second * 20,
			ExpectContinueTimeout: time.Second * 20,
			ResponseHeaderTimeout: time.Second * 20,
			IdleConnTimeout:       time.Second * 20,
		},
	},
}

func initClient() {
	proxy, _ := properties.LoadProperty("proxy", "")
	setProxy(proxy)
}

func setProxy(proxyUrlString string) (string, error) {
	var proxy func(_ *http.Request) (*url.URL, error)
	if proxyUrlString != "" {
		proxyUrl, proxyErr := url.Parse(proxyUrlString)
		if proxyErr != nil {
			return "", proxyErr
		}
		proxy = func(_ *http.Request) (*url.URL, error) {
			return proxyUrl, proxyErr
		}
	}
	properties.SaveProperty("proxy", proxyUrlString)
	client.Client.Transport.(*http.Transport).Proxy = proxy
	return "", nil
}

func getProxy(_ string) (string, error) {
	return properties.LoadProperty("proxy", "")
}

func comics(params string) (string, error) {
	page, err := strconv.Atoi(params)
	if err != nil {
		return "", err
	}
	return cacheable(
		fmt.Sprintf("COMICS$%d", page),
		time.Hour,
		func() (interface{}, error) {
			return client.Comics(page)
		},
	)
}

func comicsByTagName(params string) (string, error) {
	var paramsStruct struct {
		TagName string `json:"tag_name"`
		Page    int    `json:"page"`
	}
	err := json.Unmarshal([]byte(params), &paramsStruct)
	if err != nil {
		return "", err
	}
	return cacheable(
		fmt.Sprintf("COMICS_BY_TAG$%s$%d", paramsStruct.TagName, paramsStruct.Page),
		time.Hour,
		func() (interface{}, error) {
			return client.ComicsByTagName(paramsStruct.TagName, paramsStruct.Page)
		},
	)
}

func comicsBySearchRaw(params string) (string, error) {
	var paramsStruct struct {
		Raw  string `json:"raw"`
		Page int    `json:"page"`
	}
	err := json.Unmarshal([]byte(params), &paramsStruct)
	if err != nil {
		return "", err
	}
	return cacheable(
		fmt.Sprintf("COMICS_BY_SEARCH_RAW$%s$%d", paramsStruct.Raw, paramsStruct.Page),
		time.Hour,
		func() (interface{}, error) {
			return client.ComicByRawCondition(paramsStruct.Raw, paramsStruct.Page)
		},
	)
}

func comicInfo(params string) (string, error) {
	id, err := strconv.Atoi(params)
	if err != nil {
		return "", err
	}
	return cacheable(
		fmt.Sprintf("COMIC_INFO$%d", id),
		time.Hour,
		func() (interface{}, error) {
			return client.ComicInfo(id)
		},
	)
}

func cacheImageByUrlPath(url string) (string, error) {
	lock := HashLock(url)
	lock.Lock()
	defer lock.Unlock()
	// downloadPage
	p1 := active.FindDownloadPageByUrl(url)
	if p1 != nil {
		return path.Join(downloadPath, p1.DownloadLocalPath), nil
	}
	// downloadPageThumb
	p2 := active.FindDownloadPageThumbByUrl(url)
	if p2 != nil {
		return path.Join(downloadPath, p2.DownloadLocalPath), nil
	}
	// downloadCover
	p3 := active.FindDownloadCoverByUrl(url)
	if p3 != nil {
		return path.Join(downloadPath, p3.DownloadLocalPath), nil
	}
	// downloadCoverThumb
	p4 := active.FindDownloadCoverThumbByUrl(url)
	if p4 != nil {
		return path.Join(downloadPath, p4.DownloadLocalPath), nil
	}
	// cache
	cache := cache.FindImageCache(url)
	// no cache
	if cache == nil {
		remote, err := decodeAndSaveImage(url)
		if err != nil {
			return "", err
		}
		cache = remote
	}
	return cacheImagePath(cache.LocalPath), nil
}

func decodeAndSaveImage(url string) (*cache.ImageCache, error) {
	buff, err := decodeFromUrl(url)
	if err != nil {
		println(fmt.Sprintf("decode error : %s : %s", url, err.Error()))
		return nil, err
	}
	local := fmt.Sprintf("%x", md5.Sum([]byte(url)))
	real := cacheImagePath(local)
	err = ioutil.WriteFile(
		real,
		buff, os.FileMode(0600),
	)
	if err != nil {
		return nil, err
	}
	imageCache := cache.ImageCache{
		Url:       url,
		LocalPath: local,
	}
	err = cache.SaveImageCache(&imageCache)
	return &imageCache, err
}
