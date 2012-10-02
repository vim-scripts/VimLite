#ifndef __FTERROR_H__
#define __FTERROR_H__

#include "ftTypes.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum ErrorType_em {
    INFO    = 1,
    WARNING = 2,
    FATAL   = 4,
} ErrorType;

void Error(ErrorType err, const char *pszFormat, ...);

#ifdef __cplusplus
}
#endif


#endif /* __FTERROR_H__ */
