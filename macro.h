#ifndef __MACRO_H__
#define __MACRO_H__


#include "general.h"  /* must always come first */
#include "vstring.h"

#include "ftHashTable.h"
#include "ftCMacro.h"

CMacro * CMacroNew(const char *pszMacroID, const char *pszMacroArgs,
				   const char *pszMacroValue);
void CMacroDelete(CMacro *pCMacro);

CMacro * GetMacro(HashTable *pTable, const char *pszMacroID);

boolean AddMacro(HashTable *pTable, CMacro *pCMacro);
boolean DelMacro(HashTable *pTable, const char *pszMacroID);

void PrintMacros(HashTable *pTable);


#endif /* __MACRO_H__ */

/* vi:set tabstop=4 shiftwidth=4 noet: */
