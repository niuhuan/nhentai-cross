package nhentai

import (
	"hash/fnv"
	"sync"
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


