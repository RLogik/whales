package globals

import (
	"whales/core/environment"
)

var OUT string
var ERR string
var VERBOSE string
var PATH_LOGS string
var FILENAME_LOGS_DEBUG string
var CMD_EXPLORE string = "bash"
var WAIT_PERIOD_IN_SECONDS int = 1
var PENDING_SYMBOL string = "#"
var LOGGINGPREFIX string = ""

var WHALES_ENV_NAME string = ".whales.env"
var WHALES_SETUP_PATH string
var WHALES_PROJECT_NAME string
var WHALES_LABEL_PREFIX string = "org.whales."
var WHALES_LABEL_PREFIX_REGEX string = "^org\\.whales\\."
var WHALES_DOCKER_COMPOSE_YML string = ".whales.docker-compose.yml"
var WHALES_FILE_DOCKER_DEPTH string = ".whales.depth"
var WHALES_DOCKER_TAG_EXPLORE string = "explore"
var WHALES_DOCKER_CMD_EXPLORE string = "bash"
var WHALES_DOCKER_SERVICE string
var WHALES_DOCKER_IMAGE_NAME string
var WHALES_DOCKER_IMAGE_ID string
var WHALES_DOCKER_CONTAINER_ID string
var WHALES_PORTS_OPTIONS string

func UnpackProjectEnvironment() {
	environment.ENV_FILE_NAME = WHALES_ENV_NAME
	WHALES_SETUP_PATH = environment.ReadEnvKey("WHALES_SETUP_PATH")
	WHALES_PROJECT_NAME = environment.ReadEnvKey("WHALES_PROJECT_NAME")
	OUT = environment.ReadEnvKeyDefault("CONSOLE_OUT", "/dev/stdout")
	ERR = environment.ReadEnvKeyDefault("CONSOLE_ERR", "/dev/stderr")
	VERBOSE = environment.ReadEnvKeyDefault("CONSOLE_VERBOSE", "/dev/null")
	PATH_LOGS = environment.ReadEnvKeyDefault("CONSOLE_PATH_LOGS", "logs")
	FILENAME_LOGS_DEBUG = environment.ReadEnvKeyDefault("CONSOLE_FILENAME_LOGS_DEBUG", "debug.log")
}

// WHALES_TEMPCONTAINER_SCHEME_PREFIX
func GetTempContainerName() string {
	return "temp_" + WHALES_PROJECT_NAME
}
