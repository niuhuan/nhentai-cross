package active

import (
	"errors"
	"github.com/niuhuan/nhentai-go"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"nhentai/nhentai/constant"
	"path"
	"sync"
)

var client = nhentai.Client{}
var mutex = sync.Mutex{}
var db *gorm.DB

func Init(databaseDir string) {
	var err error
	db, err = gorm.Open(sqlite.Open(path.Join(databaseDir, "download.db")), constant.GormConfig)
	if err != nil {
		panic(err)
	}
	db.AutoMigrate(&ViewLog{})
	db.AutoMigrate(&ViewLogTag{})
	db.AutoMigrate(&Download{})
	db.AutoMigrate(&DownloadTag{})
	db.AutoMigrate(&DownloadCover{})
	db.AutoMigrate(&DownloadCoverThumb{})
	db.AutoMigrate(&DownloadPage{})
	db.AutoMigrate(&DownloadPageThumb{})
}

type ViewLog struct {
	ID            int    `gorm:"primarykey" json:"id"`
	MediaId       int    `json:"media_id"`
	TitleEnglish  string `json:"title_english"`
	TitleJapanese string `json:"title_japanese"`
	TitlePretty   string `json:"title_pretty"`
	Scanlator     string `json:"scanlator"`
	UploadDate    int    `json:"upload_date"`
	NumPages      int    `json:"num_pages"`
	NumFavorites  int    `json:"num_favorites"`
	LastViewTime  int64  `json:"last_view_time"`
	LastViewIndex int    `json:"last_view_index"`
}

type ViewLogTag struct {
	ComicId int    `gorm:"primarykey" json:"comic_id"`
	ID      int    `gorm:"primarykey" json:"id"`
	Name    string `json:"name"`
	Count   int    `json:"count"`
	Type    string `json:"type"`
	Url     string `json:"url"`
}

type Download struct {
	ID                  int    `gorm:"primarykey" json:"id"`
	MediaId             int    `json:"media_id"`
	TitleEnglish        string `json:"title_english"`
	TitleJapanese       string `json:"title_japanese"`
	TitlePretty         string `json:"title_pretty"`
	Scanlator           string `json:"scanlator"`
	UploadDate          int    `json:"upload_date"`
	NumPages            int    `json:"num_pages"`
	NumFavorites        int    `json:"num_favorites"`
	DownloadCreatedTime int64  `json:"download_created_time"`
	DownloadStatus      int    `json:"download_status"` // 未完成, 1成功, 2失败
}

type DownloadTag struct {
	ComicId int    `gorm:"primarykey" json:"comic_id"`
	ID      int    `gorm:"primarykey" json:"id"`
	Name    string `json:"name"`
	Count   int    `json:"count"`
	Type    string `json:"type"`
	Url     string `json:"url"`
}

type DownloadCover struct {
	ComicId           int    `gorm:"primarykey" json:"comic_id"`
	Url               string `gorm:"index:idx_url" json:"url"`
	T                 string `json:"t"`
	W                 int    `json:"w"`
	H                 int    `json:"h"`
	DownloadStatus    int    `json:"download_status"` // 未完成, 1成功, 2失败
	DownloadLocalPath string
}

type DownloadCoverThumb struct {
	ComicId           int    `gorm:"primarykey" json:"comic_id"`
	Url               string `gorm:"index:idx_url" json:"url"`
	T                 string `json:"t"`
	W                 int    `json:"w"`
	H                 int    `json:"h"`
	DownloadStatus    int    `json:"download_status"` // 未完成, 1成功, 2失败
	DownloadLocalPath string
}

type DownloadPage struct {
	ComicId           int    `gorm:"primarykey" json:"comic_id"`
	PageIndex         int    `gorm:"primarykey" json:"page_index"`
	Num               int    `json:"num"`
	Url               string `gorm:"index:idx_url" json:"url"`
	T                 string `json:"t"`
	W                 int    `json:"w"`
	H                 int    `json:"h"`
	DownloadStatus    int    `json:"download_status"` // 未完成, 1成功, 2失败
	DownloadLocalPath string
}

type DownloadPageThumb struct {
	ComicId           int    `gorm:"primarykey" json:"comic_id"`
	PageIndex         int    `gorm:"primarykey" json:"page_index"`
	Num               int    `json:"num"`
	Url               string `gorm:"index:idx_url" json:"url"`
	DownloadStatus    int    `json:"download_status"` // 未完成, 1成功, 2失败
	DownloadLocalPath string
}

func SaveViewInfo(info nhentai.ComicInfo) error {
	viewLog := takeViewLog(info, 0)
	tags := takeViewLogTags(info.Tags, info.Id)
	mutex.Lock()
	defer mutex.Unlock()
	return db.Transaction(func(tx *gorm.DB) error {
		err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"id",
				"media_id",
				"title_english",
				"title_japanese",
				"title_pretty",
				"scanlator",
				"upload_date",
				"num_pages",
				"num_favorites",
				"last_view_time",
			}),
		}).Create(&viewLog).Error
		if err != nil {
			return err
		}
		return saveViewTagInTx(tx, tags)
	})
}

func SaveViewIndex(info nhentai.ComicInfo, index int) error {
	viewLog := takeViewLog(info, index)
	tags := takeViewLogTags(info.Tags, info.Id)
	mutex.Lock()
	defer mutex.Unlock()
	return db.Transaction(func(tx *gorm.DB) error {
		err := tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "id"}},
			DoUpdates: clause.AssignmentColumns([]string{
				"id",
				"media_id",
				"title_english",
				"title_japanese",
				"title_pretty",
				"scanlator",
				"upload_date",
				"num_pages",
				"num_favorites",
				"last_view_time",
				"last_view_index",
			}),
		}).Create(&viewLog).Error
		if err != nil {
			return err
		}
		return saveViewTagInTx(tx, tags)
	})
}

func saveViewTagInTx(tx *gorm.DB, tags []ViewLogTag) error {
	var err error
	for i := 0; i < len(tags); i++ {
		err = tx.Clauses(clause.OnConflict{
			Columns: []clause.Column{
				{Name: "comic_id"},
				{Name: "id"},
			},
			DoUpdates: clause.AssignmentColumns([]string{
				"comic_id",
				"id",
				"type",
				"count",
				"name",
				"url",
			}),
		}).Create(&tags[i]).Error
		if err != nil {
			return err
		}
	}
	return nil
}

func takeViewLogTags(infoTags []nhentai.ComicInfoTag, comicId int) []ViewLogTag {
	tags := make([]ViewLogTag, len(infoTags))
	for i := 0; i < len(infoTags); i++ {
		tags[i] = ViewLogTag{
			ComicId: comicId,
			ID:      infoTags[i].Id,
			Type:    infoTags[i].Type,
			Count:   infoTags[i].Count,
			Name:    infoTags[i].Name,
			Url:     infoTags[i].Url,
		}
	}
	return tags
}

func takeViewLog(info nhentai.ComicInfo, index int) ViewLog {
	return ViewLog{
		ID:            info.Id,
		MediaId:       info.MediaId,
		TitleEnglish:  info.Title.English,
		TitleJapanese: info.Title.Japanese,
		TitlePretty:   info.Title.Pretty,
		Scanlator:     info.Scanlator,
		UploadDate:    info.UploadDate,
		NumPages:      info.NumPages,
		NumFavorites:  info.NumFavorites,
		LastViewTime:  constant.Timestamp(),
		LastViewIndex: index,
	}
}

func LoadLastViewIndexByComicId(comicId int) (int, error) {
	mutex.Lock()
	defer mutex.Unlock()
	var viewLog ViewLog
	err := db.Where("id = ?", comicId).Find(&viewLog).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return 0, nil
		}
		return 0, err
	}
	return viewLog.LastViewIndex, nil
}

func CreateDownload(info nhentai.ComicInfo) error {
	download := Download{
		ID:                  info.Id,
		MediaId:             info.MediaId,
		TitleEnglish:        info.Title.English,
		TitleJapanese:       info.Title.Japanese,
		TitlePretty:         info.Title.Pretty,
		Scanlator:           info.Scanlator,
		UploadDate:          info.UploadDate,
		NumPages:            info.NumPages,
		NumFavorites:        info.NumFavorites,
		DownloadCreatedTime: constant.Timestamp(),
		DownloadStatus:      0,
	}
	tags := takeDownloadTags(info.Tags, info.Id)
	cover := DownloadCover{
		ComicId:           info.Id,
		Url:               client.CoverUrl(info.MediaId, info.Images.Cover.T),
		T:                 info.Images.Cover.T,
		W:                 info.Images.Cover.W,
		H:                 info.Images.Cover.H,
		DownloadStatus:    0,
		DownloadLocalPath: "",
	}
	coverThumb := DownloadCoverThumb{
		ComicId:           info.Id,
		Url:               client.ThumbnailUrl(info.MediaId, info.Images.Thumbnail.T),
		T:                 info.Images.Thumbnail.T,
		W:                 info.Images.Thumbnail.W,
		H:                 info.Images.Thumbnail.H,
		DownloadStatus:    0,
		DownloadLocalPath: "",
	}
	pages := make([]DownloadPage, len(info.Images.Pages))
	pagesThumbs := make([]DownloadPageThumb, len(info.Images.Pages))
	for i := 0; i < len(info.Images.Pages); i++ {
		pages[i] = DownloadPage{
			ComicId:           info.Id,
			PageIndex:         i,
			Num:               i + 1,
			Url:               client.PageUrl(info.MediaId, i+1, info.Images.Pages[i].T),
			T:                 info.Images.Pages[i].T,
			W:                 info.Images.Pages[i].W,
			H:                 info.Images.Pages[i].H,
			DownloadStatus:    0,
			DownloadLocalPath: "",
		}
		pagesThumbs[i] = DownloadPageThumb{
			ComicId:           info.Id,
			PageIndex:         i,
			Num:               i + 1,
			Url:               client.PageThumbnailUrl(info.MediaId, i+1, info.Images.Pages[i].T),
			DownloadStatus:    0,
			DownloadLocalPath: "",
		}
	}
	mutex.Lock()
	defer mutex.Unlock()
	return db.Transaction(func(tx *gorm.DB) error {
		err := tx.Where("id = ?", download.ID).First(&Download{}).Error
		if err == nil {
			return errors.New("download exists")
		}
		if err != gorm.ErrRecordNotFound {
			return err
		}
		err = tx.Save(&download).Error
		if err != nil {
			return err
		}
		for i := 0; i < len(tags); i++ {
			tx.Save(&(tags[i]))
			if err != nil {
				return err
			}
		}
		err = tx.Save(&cover).Error
		if err != nil {
			return err
		}
		err = tx.Save(&coverThumb).Error
		if err != nil {
			return err
		}
		for i := 0; i < len(pages); i++ {
			tx.Save(&(pages[i]))
			if err != nil {
				return err
			}
		}
		for i := 0; i < len(pagesThumbs); i++ {
			tx.Save(&(pagesThumbs[i]))
			if err != nil {
				return err
			}
		}
		return nil
	})
}

func takeDownloadTags(infoTags []nhentai.ComicInfoTag, comicId int) []DownloadTag {
	tags := make([]DownloadTag, len(infoTags))
	for i := 0; i < len(infoTags); i++ {
		tags[i] = DownloadTag{
			ComicId: comicId,
			ID:      infoTags[i].Id,
			Type:    infoTags[i].Type,
			Count:   infoTags[i].Count,
			Name:    infoTags[i].Name,
			Url:     infoTags[i].Url,
		}
	}
	return tags
}

func LoadFirstNeedDownload() (*Download, error) {
	mutex.Lock()
	defer mutex.Unlock()
	download := Download{}
	err := db.Where("download_status = 0").Order("download_created_time DESC").First(&download).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, err
	}
	return &download, nil
}

func TheDownloadCover(id int) (*DownloadCover, error) {
	mutex.Lock()
	defer mutex.Unlock()
	cover := DownloadCover{}
	err := db.Where("comic_id = ?", id).First(&cover).Error
	return &cover, err
}

func TheDownloadCoverThumb(id int) (*DownloadCoverThumb, error) {
	mutex.Lock()
	defer mutex.Unlock()
	coverThumb := DownloadCoverThumb{}
	err := db.Where("comic_id = ?", id).First(&coverThumb).Error
	return &coverThumb, err
}

func TheDownloadNeedDownloadPages(id int, limit int) ([]DownloadPage, error) {
	mutex.Lock()
	defer mutex.Unlock()
	var pages []DownloadPage
	return pages, db.Where("comic_id = ? AND download_status = 0", id).
		Order("page_index ASC").Limit(limit).
		Find(&pages).Error
}

func TheDownloadNeedDownloadPageThumbs(id int, limit int) ([]DownloadPageThumb, error) {
	mutex.Lock()
	defer mutex.Unlock()
	var pages []DownloadPageThumb
	return pages, db.Where("comic_id = ? AND download_status = 0", id).
		Order("page_index ASC").Limit(limit).
		Find(&pages).Error
}

func SaveDownloadCoverStatus(comicId int, status int, path string) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Model(&DownloadCover{}).Where("comic_id = ?", comicId).Updates(map[string]interface{}{
		"download_status":     status,
		"download_local_path": path,
	}).Error
}

func SaveDownloadCoverThumbStatus(comicId int, status int, path string) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Model(&DownloadCoverThumb{}).Where("comic_id = ?", comicId).Updates(map[string]interface{}{
		"download_status":     status,
		"download_local_path": path,
	}).Error
}

func SaveDownloadPageStatus(comicId int, pageIndex, status int, path string) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Model(&DownloadPage{}).Where("comic_id = ? AND page_index = ?", comicId, pageIndex).Updates(map[string]interface{}{
		"download_status":     status,
		"download_local_path": path,
	}).Error
}

func SaveDownloadPageThumbStatus(comicId int, pageIndex, status int, path string) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Model(&DownloadPageThumb{}).Where("comic_id = ? AND page_index = ?", comicId, pageIndex).Updates(map[string]interface{}{
		"download_status":     status,
		"download_local_path": path,
	}).Error
}

func DownloadCoverOk(comicId int) bool {
	mutex.Lock()
	defer mutex.Unlock()
	var covers []DownloadCover
	err := db.Where("comic_id = ?", comicId).Group("download_status").Find(&covers).Error
	if err != nil {
		panic(err)
	}
	return len(covers) == 1 && covers[0].DownloadStatus == 1
}

func DownloadCoverThumbOk(comicId int) bool {
	mutex.Lock()
	defer mutex.Unlock()
	var covers []DownloadCoverThumb
	err := db.Where("comic_id = ?", comicId).Group("download_status").Find(&covers).Error
	if err != nil {
		panic(err)
	}
	return len(covers) == 1 && covers[0].DownloadStatus == 1
}

func DownloadPageOk(comicId int) bool {
	mutex.Lock()
	defer mutex.Unlock()
	var pages []DownloadPage
	err := db.Where("comic_id = ?", comicId).Group("download_status").Find(&pages).Error
	if err != nil {
		panic(err)
	}
	return len(pages) == 1 && pages[0].DownloadStatus == 1
}

func DownloadPageThumbOk(comicId int) bool {
	mutex.Lock()
	defer mutex.Unlock()
	var pages []DownloadPageThumb
	err := db.Where("comic_id = ?", comicId).Group("download_status").Find(&pages).Error
	if err != nil {
		panic(err)
	}
	return len(pages) == 1 && pages[0].DownloadStatus == 1
}

func SaveDownloadStatus(id int, status int) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Model(&Download{}).Where("id = ?", id).Updates(map[string]interface{}{
		"download_status": status,
	}).Error
}

func FindDownloadPageByUrl(url string) *DownloadPage {
	mutex.Lock()
	defer mutex.Unlock()
	page := DownloadPage{}
	err := db.Where("url = ? AND download_status = 1", url).First(&page).Error
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			panic(err)
		}
		return nil
	}
	return &page
}

func FindDownloadPageThumbByUrl(url string) *DownloadPageThumb {
	mutex.Lock()
	defer mutex.Unlock()
	page := DownloadPageThumb{}
	err := db.Where("url = ? AND download_status = 1", url).First(&page).Error
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			panic(err)
		}
		return nil
	}
	return &page
}

func FindDownloadCoverByUrl(url string) *DownloadCover {
	mutex.Lock()
	defer mutex.Unlock()
	page := DownloadCover{}
	err := db.Where("url = ? AND download_status = 1", url).First(&page).Error
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			panic(err)
		}
		return nil
	}
	return &page
}

func FindDownloadCoverThumbByUrl(url string) *DownloadCoverThumb {
	mutex.Lock()
	defer mutex.Unlock()
	page := DownloadCoverThumb{}
	err := db.Where("url = ? AND download_status = 1", url).First(&page).Error
	if err != nil {
		if err != gorm.ErrRecordNotFound {
			panic(err)
		}
		return nil
	}
	return &page
}

func HasDownload(comicId int) bool {
	mutex.Lock()
	defer mutex.Unlock()
	var download Download
	err := db.Where("id = ?", comicId).First(&download).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return false
		}
		panic(err)
	}
	return true
}

func ListDownloadComicInfo() []DownloadComicInfo {
	mutex.Lock()
	defer mutex.Unlock()
	var err error
	var downloads []Download
	var tags []DownloadTag
	var thumbs []DownloadCoverThumb
	var covers []DownloadCover
	var pages []DownloadPage
	err = db.Find(&downloads).Error
	if err != nil {
		panic(err)
	}
	err = db.Find(&tags).Error
	if err != nil {
		panic(err)
	}
	err = db.Find(&covers).Error
	if err != nil {
		panic(err)
	}
	err = db.Find(&thumbs).Error
	if err != nil {
		panic(err)
	}
	err = db.Order("page_index ASC").Find(&pages).Error
	if err != nil {
		panic(err)
	}
	var infos = make([]DownloadComicInfo, len(downloads))
	for i := 0; i < len(infos); i++ {
		infos[i] = DownloadComicInfo{
			ComicInfo: nhentai.ComicInfo{
				Id:      downloads[i].ID,
				MediaId: downloads[i].MediaId,
				Title: nhentai.ComicInfoTitle{
					English:  downloads[i].TitleEnglish,
					Japanese: downloads[i].TitleJapanese,
					Pretty:   downloads[i].TitlePretty,
				},
				Images: nhentai.ComicInfoImages{
					Pages:     filterPages(pages, downloads[i].ID),
					Cover:     filterCover(covers, downloads[i].ID),
					Thumbnail: filterCoverThumb(thumbs, downloads[i].ID),
				},
				Scanlator:    downloads[i].Scanlator,
				UploadDate:   downloads[i].UploadDate,
				Tags:         filterTags(tags, downloads[i].ID),
				NumPages:     downloads[i].NumPages,
				NumFavorites: downloads[i].NumFavorites,
			},
			DownloadStatus: downloads[i].DownloadStatus,
		}
	}
	return infos
}

func filterPages(pages []DownloadPage, id int) []nhentai.ImageInfo {
	rsp := make([]nhentai.ImageInfo, 0)
	for i := 0; i < len(pages); i++ {
		if pages[i].ComicId == id {
			rsp = append(rsp, nhentai.ImageInfo{
				T: pages[i].T,
				W: pages[i].W,
				H: pages[i].H,
			})
		}
	}
	return rsp
}

func filterTags(tags []DownloadTag, id int) []nhentai.ComicInfoTag {
	rsp := make([]nhentai.ComicInfoTag, 0)
	for i := 0; i < len(tags); i++ {
		if tags[i].ComicId == id {
			rsp = append(rsp, nhentai.ComicInfoTag{
				Id:    tags[i].ID,
				Name:  tags[i].Name,
				Count: tags[i].Count,
				Type:  tags[i].Type,
				Url:   tags[i].Url,
			})
		}
	}
	return rsp
}

func filterCover(covers []DownloadCover, id int) nhentai.ImageInfo {
	for i := 0; i < len(covers); i++ {
		if covers[i].ComicId == id {
			return nhentai.ImageInfo{
				T: covers[i].T,
				W: covers[i].W,
				H: covers[i].H,
			}
		}
	}
	return nhentai.ImageInfo{}
}

func filterCoverThumb(covers []DownloadCoverThumb, id int) nhentai.ImageInfo {
	for i := 0; i < len(covers); i++ {
		if covers[i].ComicId == id {
			return nhentai.ImageInfo{
				T: covers[i].T,
				W: covers[i].W,
				H: covers[i].H,
			}
		}
	}
	return nhentai.ImageInfo{}
}

type DownloadComicInfo struct {
	nhentai.ComicInfo
	DownloadStatus int `json:"download_status"`
}

func ResetAllDownload() {
	mutex.Lock()
	defer mutex.Unlock()
	var err error
	err = db.Exec("UPDATE download set download_status = 0 WHERE download_status = 2").Error
	if err != nil {
		panic(err)
	}
	err = db.Exec("UPDATE download_cover set download_status = 0 WHERE download_status = 2").Error
	if err != nil {
		panic(err)
	}
	err = db.Exec("UPDATE download_cover_thumb set download_status = 0 WHERE download_status = 2").Error
	if err != nil {
		panic(err)
	}
	err = db.Exec("UPDATE download_page set download_status = 0 WHERE download_status = 2").Error
	if err != nil {
		panic(err)
	}
	err = db.Exec("UPDATE download_page_thumb set download_status = 0 WHERE download_status = 2").Error
	if err != nil {
		panic(err)
	}
}

func MarkComicDeleting(id int) {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Model(&Download{}).Where("id = ?", id).Update("download_status", 3).Error
	if err != nil {
		panic(err)
	}
}

func LoadFirstNeedDelete() *Download {
	mutex.Lock()
	defer mutex.Unlock()
	download := Download{}
	err := db.Where("download_status = 3").Order("download_created_time ASC").First(&download).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil
		}
		panic(err)
	}
	return &download
}

func DeletedComic(id int) {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Transaction(func(tx *gorm.DB) error {
		var err error
		err = tx.Unscoped().Delete(&Download{}, "id = ?", id).Error
		if err != nil {
			return err
		}
		err = tx.Unscoped().Delete(&DownloadCover{}, "comic_id = ?", id).Error
		if err != nil {
			return err
		}
		err = tx.Unscoped().Delete(&DownloadPage{}, "comic_id = ?", id).Error
		if err != nil {
			return err
		}
		err = tx.Unscoped().Delete(&DownloadTag{}, "comic_id = ?", id).Error
		if err != nil {
			return err
		}
		err = tx.Unscoped().Delete(&DownloadCoverThumb{}, "comic_id = ?", id).Error
		if err != nil {
			return err
		}
		err = tx.Unscoped().Delete(&DownloadPageThumb{}, "comic_id = ?", id).Error
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		panic(err)
	}
}
