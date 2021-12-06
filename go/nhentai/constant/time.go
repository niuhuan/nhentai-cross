package constant

import "time"

// Timestamp 获取当前的Unix时间戳
func Timestamp() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}
