#include <gtest/gtest.h>

#include "ftError.h"


TEST(ftError, Error)
{
	Error(INFO, "%s\n", "info");
	Error(WARNING, "%s\n", "warning");
	//Error(FATAL, "%s\n", "fatal");
}

