#include <log>

Logger logger;

public OnPluginStart()
{
	logger = Logger("test");
	logger.log("A random info message");
	logger.success("We did good");
	logger.warn("Watch out!");
	logger.error("Uh oh...");

	logger.warn("Huh %s", "test");
}