#ifndef __CXXLEXPRVTDATA_H__
#define __CXXLEXPRVTDATA_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef struct CxxLexPrvtData_st {
    int yySavedState;
} CxxLexPrvtData;

int CxxLexPrvtData_Init(CxxLexPrvtData *pPrvtData);

void CxxLexPrvtData_Term(CxxLexPrvtData *pPrvtData);

#ifdef __cplusplus
}
#endif

#endif /* __CXXLEXPRVTDATA_H__ */
