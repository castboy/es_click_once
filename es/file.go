package modules

import (
	"io/ioutil"
	"os"
)

func Rd(path string) []byte {
	fi, err := os.Open(path)
	if err != nil {
		panic(err)
	}
	defer fi.Close()
	fd, err := ioutil.ReadAll(fi)

	return fd
}

func Wr(file string, b []byte) error {
	return ioutil.WriteFile(file, b, 0644)
}

func WrAppend(file string, b []byte) error {
	f, err := os.OpenFile(file, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
	_, err = f.Write(b)
	defer f.Close()

	return err
}
