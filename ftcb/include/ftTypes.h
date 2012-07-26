#ifndef __FTTYPES_H__
#define __FTTYPES_H__


#ifdef __cplusplus
extern "C" {
#endif

typedef enum Bool_em {
	False = 0,
	True = 1
} Bool;

typedef enum VisitResult_em {
	VISIT_CONTINUE,
	VISIT_BREAK
} VisitResult;

#define FT_SUCCESS      0
#define FT_FAILED       1
#define FT_NO_MEMORY    2
#define FT_NOT_FOUND    3

typedef int (*CompareFunc)(void *pData1, void *pData2);

typedef void (*DestroyFunc)(void *pData);

typedef size_t (*HashFunc)(void *pKey, size_t uBucketSize);

typedef void *(*CopyFunc)(void *pData);

/* 遍历时的访问函数 */
typedef VisitResult (*VisitFunc)(void *pData, void *pPrivateData);

#ifdef __cplusplus
}
#endif


#endif /* __FTTYPES_H__ */
