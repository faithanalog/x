package main

import (
	"log"
	"os"
	"os/exec"
	"io/ioutil"
)

func getTTY() (string, error) {
	const fd0 = "/proc/self/fd/0"
	dest, err := os.Readlink(fd0)
	if err != nil {
		return "", err
	}
	return dest, nil
}

func main() {
	tty, err := getTTY()
	if err != nil {
		println("We weren't able to get the current TTY! This only works on")
		println("linux, so if you're not on linux that's why.")
		log.Fatal(err)
	}

	cmd := exec.Command("cat")

	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Start()
	if err != nil {
		log.Fatal(err)
	}

	err = ioutil.WriteFile(tty, []byte("Hello! Type some stuff to get it echo'd by `cat`\n"), os.ModeCharDevice)
	if err != nil {
		log.Fatal(err)
	}

	err = cmd.Wait()
	if err != nil {
		log.Fatal(err)
	}

}
