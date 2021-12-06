package properties

import (
	"errors"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
	"nhentai/nhentai/constant"
	"path"
	"strconv"
)

var db *gorm.DB

func Init(databaseDir string) {
	var err error
	db, err = gorm.Open(sqlite.Open(path.Join(databaseDir, "properties.db")), constant.GormConfig)
	if err != nil {
		panic(err)
	}
	db.AutoMigrate(&Property{})
}

type Property struct {
	gorm.Model
	K string `gorm:"index:uk_k,unique"`
	V string
}

func LoadProperty(name string, defaultValue string) (string, error) {
	var property Property
	err := db.First(&property, "k", name).Error
	if err == nil {
		return property.V, nil
	}
	if gorm.ErrRecordNotFound == err {
		return defaultValue, nil
	}
	panic(errors.New("?"))
}

func SaveProperty(name string, value string) error {
	return db.Clauses(clause.OnConflict{
		Columns:   []clause.Column{{Name: "k"}},
		DoUpdates: clause.AssignmentColumns([]string{"created_at", "updated_at", "v"}),
	}).Create(&Property{
		K: name,
		V: value,
	}).Error
}

func LoadBoolProperty(name string, defaultValue bool) (bool, error) {
	stringValue, err := LoadProperty(name, strconv.FormatBool(defaultValue))
	if err != nil {
		return false, err
	}
	return strconv.ParseBool(stringValue)
}

func LoadIntProperty(name string, defaultValue int) (int, error) {
	var property Property
	err := db.First(&property, "k", name).Error
	if err == nil {
		return strconv.Atoi(property.V)
	}
	if gorm.ErrRecordNotFound == err {
		return defaultValue, nil
	}
	panic(errors.New("?"))
}
