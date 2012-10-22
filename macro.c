#include <stdio.h>
#include <string.h>

#include "macro.h"
#include "routines.h"
#include "ftString.h"
#include "ftStack.h"

CMacro * CMacroNew(const char *pszMacroID, const char *pszMacroArgs,
				   const char *pszMacroValue)
{
	char szBuf[BUFSIZ];
	Stack *pArgs;
	CMacro *pCMacro = xMalloc(sizeof(CMacro), CMacro);
	memset(pCMacro, 0, sizeof(CMacro));
	pArgs = Stack_Create(16);
	if ( pArgs == NULL )
	{
		error(FATAL, "out of memory");
	}

	pCMacro->pszMacroID = xMalloc(strlen(pszMacroID) + 1, char);
	strcpy(pCMacro->pszMacroID, pszMacroID);

	pCMacro->bIsFuncLike = (Bool)(pszMacroArgs[0] != '\0');
	if ( pCMacro->bIsFuncLike )
	{
		int i;
		StrIter iter;
		vString *args = vStringNewInit(pszMacroArgs); /* 包括括号的原始文本 */
		StrStripMod(args->buffer, " \f\n\r\t\v()");
		args->length = strlen(args->buffer);

		StrIterSplitInit(&iter, vStringValue(args), STR_MAX_REPLACE);
		while ( StrIterSplitNext(&iter, ",", szBuf, sizeof(szBuf)) )
		{
			char *s = NULL;
			if ( IsBufferOverflow(szBuf, sizeof(szBuf)) )
			{
				error(WARNING,
					  "Identifier of macro argument is too long! Truncation!\n");
				szBuf[sizeof(szBuf)-1] = '\0';
			}
			StrStripSpaceMod(szBuf);
			if ( strcmp(szBuf, "...") == 0 )
			{
				/* 可变参数 */
				strcpy(szBuf, "__VA_ARGS__");
			}
			else if ( StrEndsWith(szBuf, "...", 0, STR_END_INDEX) )
			{
				/* gcc 形式的可变参数。eg. #define p(arg...) */
				StrSliceMod(szBuf, 0, -3);
			}
			s = xMalloc(strlen(szBuf) + 1, char);
			strcpy(s, szBuf);
			Stack_Push(pArgs, (void *)s);
		}

		pCMacro->uArgc = Stack_GetCount(pArgs);
		pCMacro->ppszArgv = xMalloc(pCMacro->uArgc, char *);
		for ( i = pCMacro->uArgc - 1; i >= 0; i-- )
		{
			void *pData = NULL;
			Stack_Pop(pArgs, &pData);
			pCMacro->ppszArgv[i] = (char *)pData;
		}

		vStringDelete(args);
	}
	else
	{
		pCMacro->uArgc = 0;
		pCMacro->ppszArgv = NULL;
	}

	pCMacro->pszMacroValue = xMalloc(strlen(pszMacroValue) + 1, char);
	strcpy(pCMacro->pszMacroValue, pszMacroValue);

	Stack_Destroy(pArgs, NULL);

	return pCMacro;
}

void CMacroDelete(CMacro *pCMacro)
{
	CMacro_Destroy(pCMacro);
}

CMacro * GetMacro(HashTable *pTable, const char *pszMacroID)
{
	CMacro m;
	void *pData = NULL;
	m.pszMacroID = (char *)pszMacroID;
	if ( HashTable_Find(pTable, (void *)&m, CMacro_Hash, CMacro_Compare, &pData) )
	{
		return pData;
	}
	else
	{
		return NULL;
	}
}

boolean AddMacro(HashTable *pTable, CMacro *pCMacro)
{
	return HashTable_Insert(pTable, pCMacro, CMacro_Hash,
							CMacro_Compare, (DestroyFunc)CMacro_Destroy);
}

boolean DelMacro(HashTable *pTable, const char *pszMacroID)
{
	CMacro m;
	m.pszMacroID = (char *)pszMacroID;
	return HashTable_Remove(pTable, (void *)&m, CMacro_Hash,
							CMacro_Compare, (DestroyFunc)CMacro_Destroy);
}

void PrintMacros(HashTable *pTable)
{
	void *pData;
	CMacro *p;
	HashTableIter iter;
	HashTable_IterInit(&iter, pTable);
	while ( HashTable_IterNext(&iter, &pData) )
	{
		p = (CMacro *)pData;
		if ( p->bIsFuncLike )
		{
			boolean firstEnter = TRUE;
			size_t i = 0;
			printf("#define %s(", p->pszMacroID);
			for ( i = 0; i < p->uArgc; i++ )
			{
				if ( !firstEnter )
				{
					printf(", ");
				}
				printf("%s", p->ppszArgv[i]);
				firstEnter = FALSE;
			}
			printf(") ");
			printf("%s\n" ,p->pszMacroValue);
		}
		else
		{
			printf("#define %s %s\n", p->pszMacroID, p->pszMacroValue);
		}
	}
}

/* vi:set tabstop=4 shiftwidth=4 noet: */
