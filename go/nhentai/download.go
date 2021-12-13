package nhentai

import (
	"fmt"
	"io/ioutil"
	"nhentai/nhentai/constant"
	"nhentai/nhentai/database/active"
	"os"
	"path"
	"sync"
	"time"
)

var initDownloadFlag bool
var downloadThreadCount = 1
var downloadThreadFetch = 100
var downloadRunning = false
var downloadRestart = false

func initDownload() {
	if initDownloadFlag {
		return
	}
	active.ResetAllDownload()
	initDownloadFlag = true
	downloadRunning = true
	go downloadBegin()
}

// 下载周期中, 每个下载单元会调用此方法, 如果返回true应该停止当前动作
func downloadHasStop() bool {
	if !downloadRunning {
		return true
	}
	if downloadRestart {
		downloadRestart = false
		return true
	}
	return false
}

// 删除第一个需要删除的漫画, 成功删除返回true
func downloadDelete() bool {
	needDelete := active.LoadFirstNeedDelete()
	if needDelete != nil {
		relativeFolder := fmt.Sprintf("%d/%d", needDelete.ID, needDelete.MediaId)
		absoluteFolder := path.Join(downloadPath, relativeFolder)
		err := os.RemoveAll(absoluteFolder)
		if err != nil {
			panic(err)
		}
		active.DeletedComic(needDelete.ID)
		return true
	}
	return false
}

// 下载启动/重新启动会暂停三秒
func downloadBegin() {
	time.Sleep(time.Second * 3)
	// 每次下载完一个漫画, 或者启动的时候, 首先进行删除任务
	for downloadDelete() {
	}
	if downloadHasStop() {
		return
	}
	go downloadLoadComic()
}

// 加载第一个需要下载的漫画
func downloadLoadComic() {
	if downloadHasStop() {
		go downloadBegin()
		return
	}
	// 找到第一个要下载的漫画, 查库有错误就停止, 因为这些错误很少出现, 一旦出现必然是严重的, 例如数据库文件突然被删除
	downloadingComic, err := active.LoadFirstNeedDownload()
	if err != nil {
		panic(err)
	}
	if downloadingComic == nil {
		println("没有找到要下载的漫画")
		go downloadBegin()
		return
	}
	go downloadProcessDownloadingComic(downloadingComic)
}

func downloadProcessDownloadingComic(downloadingComic *active.Download) {
	if downloadHasStop() {
		go downloadBegin()
		return
	}
	//
	relativeFolder := fmt.Sprintf("%d/%d", downloadingComic.ID, downloadingComic.MediaId)
	absoluteFolder := path.Join(downloadPath, relativeFolder)
	constant.ObtainDir(absoluteFolder)
	// 下载封面
	cover, err := active.TheDownloadCover(downloadingComic.ID)
	if err != nil {
		panic(err)
	}
	if cover.DownloadStatus == 0 {
		buff, err := downloadDecodeUrl(cover.Url)
		if buff != nil {
			coverName := "cover"
			relativeCover := path.Join(relativeFolder, coverName)
			absoluteCover := path.Join(absoluteFolder, coverName)
			err = ioutil.WriteFile(absoluteCover, buff, constant.CreateFileMode)
			if err != nil {
				panic(err)
			}
			active.SaveDownloadCoverStatus(downloadingComic.ID, 1, relativeCover)
		} else {
			active.SaveDownloadCoverStatus(downloadingComic.ID, 2, "")
		}
	}
	// 下载封面缩略图
	coverThumb, err := active.TheDownloadCoverThumb(downloadingComic.ID)
	if err != nil {
		panic(err)
	}
	if coverThumb.DownloadStatus == 0 {
		buff, err := downloadDecodeUrl(coverThumb.Url)
		if buff != nil {
			coverName := "cover_thumb"
			relativeCoverThumb := path.Join(relativeFolder, coverName)
			absoluteCoverThumb := path.Join(absoluteFolder, coverName)
			err = ioutil.WriteFile(absoluteCoverThumb, buff, constant.CreateFileMode)
			if err != nil {
				panic(err)
			}
			active.SaveDownloadCoverThumbStatus(downloadingComic.ID, 1, relativeCoverThumb)
		} else {
			active.SaveDownloadCoverThumbStatus(downloadingComic.ID, 2, "")
		}
	}
	// 暂停检测
	if downloadHasStop() {
		go downloadBegin()
		return
	}
	// 下载漫画
	// WARNING 无限循环
	for {
		downloadingPictures, err := active.TheDownloadNeedDownloadPages(downloadingComic.ID, downloadThreadFetch)
		if err != nil {
			panic(err)
		}
		if len(downloadingPictures) == 0 {
			break
		}
		// 多线程下载漫画
		hasStop := func() bool {
			channel := make(chan int, downloadThreadCount)
			defer close(channel)
			wg := sync.WaitGroup{}
			for i := 0; i < len(downloadingPictures); i++ {
				// 暂停检测
				if downloadHasStop() {
					wg.Wait()
					return true
				}
				channel <- 0
				wg.Add(1)
				// 不放入携程, 防止i已经变化
				pagePoint := &(downloadingPictures[i])
				go func() {
					// 下载漫画
					buff, err := downloadDecodeUrl(pagePoint.Url)
					if buff != nil {
						pageName := fmt.Sprintf("p_%d", pagePoint.PageIndex)
						relativePageName := path.Join(relativeFolder, pageName)
						absolutePageName := path.Join(absoluteFolder, pageName)
						err = ioutil.WriteFile(absolutePageName, buff, constant.CreateFileMode)
						if err != nil {
							panic(err)
						}
						active.SaveDownloadPageStatus(downloadingComic.ID, pagePoint.PageIndex, 1, relativePageName)
					} else {
						active.SaveDownloadPageStatus(downloadingComic.ID, pagePoint.PageIndex, 2, "")
					}
					// 下载漫画
					<-channel
					wg.Done()
				}()
			}
			wg.Wait()
			return false
		}()
		if hasStop {
			go downloadBegin()
			return
		}
	}
	// 下载漫画
	// WARNING 无限循环
	for {
		downloadingPictureThumbs, err := active.TheDownloadNeedDownloadPageThumbs(downloadingComic.ID, downloadThreadFetch)
		if err != nil {
			panic(err)
		}
		if len(downloadingPictureThumbs) == 0 {
			break
		}
		// 多线程下载漫画
		hasStop := func() bool {
			channel := make(chan int, downloadThreadCount)
			defer close(channel)
			wg := sync.WaitGroup{}
			for i := 0; i < len(downloadingPictureThumbs); i++ {
				// 暂停检测
				if downloadHasStop() {
					wg.Wait()
					return true
				}
				channel <- 0
				wg.Add(1)
				// 不放入携程, 防止i已经变化
				pagePoint := &(downloadingPictureThumbs[i])
				go func() {
					//
					buff, err := downloadDecodeUrl(pagePoint.Url)
					if buff != nil {
						pageThumbName := fmt.Sprintf("p_%d_t", pagePoint.PageIndex)
						relativePageThumbName := path.Join(relativeFolder, pageThumbName)
						absolutePageThumbName := path.Join(absoluteFolder, pageThumbName)
						err = ioutil.WriteFile(absolutePageThumbName, buff, constant.CreateFileMode)
						if err != nil {
							panic(err)
						}
						err = active.SaveDownloadPageThumbStatus(downloadingComic.ID, pagePoint.PageIndex, 1, relativePageThumbName)
						if err != nil {
							panic(err)
						}
					} else {
						err = active.SaveDownloadPageThumbStatus(downloadingComic.ID, pagePoint.PageIndex, 2, "")
						if err != nil {
							panic(err)
						}
					}
					//
					<-channel
					wg.Done()
				}()
			}
			wg.Wait()
			return false
		}()
		if hasStop {
			go downloadBegin()
			return
		}
	}
	// 总结下载进度
	if active.DownloadCoverOk(downloadingComic.ID) && active.DownloadCoverThumbOk(downloadingComic.ID) &&
		active.DownloadPageOk(downloadingComic.ID) && active.DownloadPageThumbOk(downloadingComic.ID) {
		err := active.SaveDownloadStatus(downloadingComic.ID, 1)
		if err != nil {
			panic(err)
		}
	} else {
		err := active.SaveDownloadStatus(downloadingComic.ID, 2)
		if err != nil {
			panic(err)
		}
	}
	go downloadBegin()
}

func downloadDecodeUrl(url string) ([]byte, error) {
	buff, err := decodeFromRemote(url)
	if buff != nil {
		return buff, nil
	}
	for i := 0; i < 5; i++ {
		buff, err = decodeFromUrl(url)
		if err != nil {
			continue
		}
		if buff != nil {
			return buff, nil
		}
	}
	return nil, err
}
