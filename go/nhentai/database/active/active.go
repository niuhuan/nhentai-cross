package active

import (
	"github.com/niuhuan/nhentai-go"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"nhentai/nhentai/constant"
	"path"
	"sync"
)

var mutex = sync.Mutex{}
var db *gorm.DB

func Init(databaseDir string) {
	var err error
	db, err = gorm.Open(sqlite.Open(path.Join(databaseDir, "cache.db")), constant.GormConfig)
	if err != nil {
		panic(err)
	}
	db.AutoMigrate(&ViewLog{})
	db.AutoMigrate(&ViewLogTag{})
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

func SaveViewInfo(info nhentai.ComicInfo) error {
	viewLog := takeLog(info, 0)
	tags := takeTags(info.Tags, info.Id)
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
		return saveTagInTx(tx, tags)
	})
}

func SaveViewIndex(info nhentai.ComicInfo, index int) error {
	viewLog := takeLog(info, index)
	tags := takeTags(info.Tags, info.Id)
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
		return saveTagInTx(tx, tags)
	})
}

func saveTagInTx(tx *gorm.DB, tags []ViewLogTag) error {
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

func takeTags(infoTags []nhentai.ComicInfoTag, comicId int) []ViewLogTag {
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

func takeLog(info nhentai.ComicInfo, index int) ViewLog {
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
