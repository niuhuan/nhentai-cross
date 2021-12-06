package constant

import (
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
	"hash/fnv"
	"os"
	"sync"
)

var (
	CreateDirMode  = os.FileMode(0700)
	CreateFileMode = os.FileMode(0600)
	GormConfig     = &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
		NamingStrategy: schema.NamingStrategy{
			SingularTable: true,
		},
	}
)

var hashMutex []*sync.Mutex

func init() {
	for i := 0; i < 32; i++ {
		hashMutex = append(hashMutex, &sync.Mutex{})
	}
}

// HashLock Hash一样的图片不同时处理
func HashLock(key string) *sync.Mutex {
	hash := fnv.New32()
	hash.Write([]byte(key))
	return hashMutex[int(hash.Sum32()%uint32(len(hashMutex)))]
}
