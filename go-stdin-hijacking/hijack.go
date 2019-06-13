package main

import (
	"log"
	"os"
	"os/exec"
	"io/ioutil"
	"errors"
)

func getTTY() (string, error) {
	const tty = "/dev/tty"
	info, err := os.Stat(tty)
	if err != nil {
		return "", err
	}
	mode := info.Mode()
	if ((mode & os.ModeDevice) != 0) || ((mode & os.ModeCharDevice) != 0) {
		return tty, nil
	} else {
		return "", errors.New("/dev/tty is not a device file!")
	}
}

func main() {
	tty, err := getTTY()
	if err != nil {
		println("We weren't able to get the current TTY! This only works on")
		println("linux and mac, so if you're on something else thats why.")
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
