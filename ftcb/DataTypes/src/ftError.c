#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "ftError.h"

void Error(ErrorType err, const char *pszFormat, ...)
{
	va_list ap;
	const char *psz = NULL;

	switch ( err )
	{
		case INFO:
			psz = "Info: ";
			break;
		case WARNING:
			psz = "Warning: ";
			break;
		case FATAL:
			psz = "Fatal: ";
			break;
		default:
			psz = "";
			break;
	}

	va_start(ap, pszFormat);
	fprintf (stderr, "%s", psz);
	vfprintf(stderr, pszFormat, ap);
	/*fputs("\n", stderr);*/
	va_end(ap);

	if ( err == FATAL )
	{
		exit(1);
	}
}

