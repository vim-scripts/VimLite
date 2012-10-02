#include <stdlib.h>
#include "CxxLexPrvtData.h"

int CxxLexPrvtData_Init(CxxLexPrvtData *pPrvtData)
{
    pPrvtData->yySavedState = 0;
    return 0;
}

void CxxLexPrvtData_Term(CxxLexPrvtData *pPrvtData)
{
    if ( pPrvtData != NULL )
    {
        /* TODO */
    }
}

