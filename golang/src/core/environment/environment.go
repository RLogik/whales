package environment

import (
	"errors"
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

var ENV_FILE_NAME string

/* ---------------------------------------------------------------- *
 * EXPORTS
 * ---------------------------------------------------------------- */

func ReadEnvKey(key string, optional ...string) string {
	value, err := readEnvKey(key, optional...)
	if err != nil {
		log.Fatal(err)
	}
	return value
}

func ReadEnvKeyAllowMissing(key string, optional ...string) string {
	value, _ := readEnvKey(key, optional...)
	return value
}

func ReadEnvKeyDefault(key string, valueDefault string, optional ...string) string {
	value, _ := readEnvKey(key, optional...)
	if value == "" {
		return valueDefault
	}
	return value
}

/* ---------------------------------------------------------------- *
 * PRIVATE
 * ---------------------------------------------------------------- */

func loadEnvFile(fName string) error {
	return godotenv.Load(fName)
}

func getEnvKey(key string) string {
	return os.Getenv(key)
}

func readEnvKey(key string, optional ...string) (string, error) {
	var fName string = ENV_FILE_NAME
	var err error
	var value string
	if len(optional) > 0 {
		fName = optional[0]
	}
	err = loadEnvFile(fName)
	if err != nil {
		log.Fatalf("Could not read environment file, \033[1m%s\033[0m!\n", fName)
	}
	err = nil
	value = getEnvKey(key)
	if value == "" {
		err = errors.New(fmt.Sprintf("Environment key \033[1m%s\033[0m missing or empty in environment file \033[1m%s\033[0m!", key, fName))
	}
	return value, err
}
