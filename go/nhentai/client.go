package nhentai

import (
	"context"
	"crypto/md5"
	"encoding/json"
	"fmt"
	source "github.com/niuhuan/nhentai-go"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"nhentai/nhentai/database/cache"
	"nhentai/nhentai/database/properties"
	"os"
	"strconv"
	"time"
)

var webAddr string
var imgAddr string

var dialer = &net.Dialer{
	Timeout:   30 * time.Second,
	KeepAlive: 30 * time.Second,
}
var client = &source.Client{
	Client: http.Client{
		Transport: &http.Transport{
			Proxy:                 nil,
			TLSHandshakeTimeout:   time.Second * 10,
			ExpectContinueTimeout: time.Second * 10,
			ResponseHeaderTimeout: time.Second * 10,
			IdleConnTimeout:       time.Second * 10,
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				if addr == "nhentai.net:443" {
					if webAddr != "" {
						return dialer.DialContext(ctx, network, webAddr)

					}
				} else if addr == "t.nhentai.net:443" || addr == "i.nhentai.net:443" || addr == "t5.nhentai.net:443" {
					if imgAddr != "" {
						return dialer.DialContext(ctx, network, imgAddr)

					}
				}
				return dialer.DialContext(ctx, network, addr)
			},
		},
	},
}

func initClient() {
	proxy, _ := properties.LoadProperty("proxy", "")
	setProxy(proxy)
	webAddr, _ = properties.LoadProperty("webAddr", "")
	imgAddr, _ = properties.LoadProperty("imgAddr", "")
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

func setWebAddress(host string) (string, error) {
	properties.SaveProperty("webAddr", host)
	webAddr = host
	return "", nil
}

func getWebAddress(_ string) (string, error) {
	return webAddr, nil
}

func setImgAddress(host string) (string, error) {
	properties.SaveProperty("imgAddr", host)
	imgAddr = host
	return "", nil
}

func getImgAddress(_ string) (string, error) {
	return imgAddr, nil
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
	cache := cache.FindImageCache(url)
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
