package cache

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"nhentai/nhentai/constant"
	"path"
	"sync"
	"time"
)

var mutex = sync.Mutex{}
var db *gorm.DB

type NetworkCache struct {
	gorm.Model
	K string `gorm:"index:uk_k,unique"`
	V string
}

type ImageCache struct {
	gorm.Model
	Url       string `gorm:"index:uk_url,unique" json:"fileServer"`
	LocalPath string `json:"localPath"`
	FileSize  int64  `json:"fileSize"`
}

func Init(databaseDir string) {
	var err error
	db, err = gorm.Open(sqlite.Open(path.Join(databaseDir, "cache.db")), constant.GormConfig)
	if err != nil {
		panic(err)
	}
	db.AutoMigrate(&NetworkCache{})
	db.AutoMigrate(&ImageCache{})
}

func LoadCache(key string, expire time.Duration) (string, error) {
	mutex.Lock()
	defer mutex.Unlock()
	var cache NetworkCache
	err := db.First(&cache, "k = ? AND updated_at > ?", key, time.Now().Add(expire*-1)).Error
	if err == nil {
		return cache.V, nil
	}
	if gorm.ErrRecordNotFound == err {
		return "", nil
	}
	return "", err
}

func SaveCache(key string, value string) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "k"}},
		DoUpdates: clause.AssignmentColumns([]string{"created_at", "updated_at", "v"}),
	}).Create(&NetworkCache{
		K: key,
		V: value,
	}).Error
}

func RemoveCache(key string) error {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Unscoped().Delete(&NetworkCache{}, "k = ?", key).Error
	if err == gorm.ErrRecordNotFound {
		return nil
	}
	return err
}

func RemoveCaches(like string) error {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Unscoped().Delete(&NetworkCache{}, "k LIKE ?", like).Error
	if err == gorm.ErrRecordNotFound {
		return nil
	}
	return err
}

func RemoveAllCache() error {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Unscoped().Delete(&NetworkCache{}, "1 = 1").Error
	if err != nil {
		return err
	}
	return db.Raw("VACUUM").Error
}

func RemoveEarliestCache(earliest time.Time) error {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Unscoped().Where("strftime('%s',updated_at) < strftime('%s',?)", earliest).
		Delete(&NetworkCache{}).Error
	if err != nil {
		return err
	}
	return db.Raw("VACUUM").Error
}

func SaveImageCache(remote *ImageCache) error {
	mutex.Lock()
	defer mutex.Unlock()
	return db.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "url"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"updated_at",
			"file_size",
			"local_path",
		}),
	}).Create(remote).Error
}

func FindImageCache(url string) *ImageCache {
	mutex.Lock()
	defer mutex.Unlock()
	var imageCache ImageCache
	err := db.First(&imageCache, "url = ?", url).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil
		} else {
			panic(err)
		}
	}
	return &imageCache
}

func RemoveAllImageCache() error {
	mutex.Lock()
	defer mutex.Unlock()
	err := db.Unscoped().Delete(&ImageCache{}, "1 = 1").Error
	if err != nil {
		return err
	}
	return db.Raw("VACUUM").Error
}

func EarliestImageCache(earliest time.Time, pageSize int) ([]ImageCache, error) {
	mutex.Lock()
	defer mutex.Unlock()
	var images []ImageCache
	err := db.Where("strftime('%s',updated_at) < strftime('%s',?)", earliest).
		Order("updated_at").Limit(pageSize).Find(&images).Error
	return images, err
}

func DeleteImageCache(images []ImageCache) error {
	mutex.Lock()
	defer mutex.Unlock()
	if len(images) == 0 {
		return nil
	}
	ids := make([]uint, len(images))
	for i := 0; i < len(images); i++ {
		ids[i] = images[i].ID
	}
	return db.Unscoped().Model(&ImageCache{}).Delete("id in ?", ids).Error
}
