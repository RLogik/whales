package main

import (
	// "log"
	// os_exec "os/exec"
	// "reflect"
	"whales/core/globals"
	// "whales/core/utils"
	// "whales/core/environment"
	"whales/docker/meta"
	// "whales/docker/docker"
)

func main() {
	globals.UnpackProjectEnvironment()
	meta.WhaleCall()
}
