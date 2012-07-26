// std::map 用字符串作为键值的话，太慢了，所以要自己做一个

#ifndef __STRMAP_HPP__
#define __STRMAP_HPP__

#include <string>
#include "ftHashTable.h"

class StrMapKeyError {
public:
    StrMapKeyError(const std::string &key)
    {
        this->key = key;
    }
    std::string key;
};

template<typename TValue>
class StrMap {
public:
    StrMap();
    ~StrMap();

    typedef size_t size_type;

    bool HasKey(const std::string &key);

    void Clear();

    TValue GetItem(const std::string &key);

    void SetItem(const std::string &key, const TValue &val);

    TValue Pop(const std::string &key);

    size_type GetCount()
    { return HashTable_GetCount(m_table); }

    bool IsEmpty()
    { return GetCount() == 0; }

private:
    HashTable *m_table; // 哈希表
};

template<typename TValue>
class StrMapItem {
public:
    std::string key;
    TValue val;
};

template<typename TValue>
int StrMapItem_Compare(void *p1, void *p2)
{
    StrMapItem<TValue> *it1 = (StrMapItem<TValue> *)p1;
    StrMapItem<TValue> *it2 = (StrMapItem<TValue> *)p2;
    return strcmp(it1->key.c_str(), it2->key.c_str());
}

template<typename TValue>
void StrMapItem_Destroy(void *p)
{
    StrMapItem<TValue> *it = (StrMapItem<TValue> *)p;
    delete it;
}

template<typename TValue>
size_t StrMapItem_Hash(void *p, size_t count)
{
    StrMapItem<TValue> *it = (StrMapItem<TValue> *)p;
    return HashString((void *)it->key.c_str(), count);
}

template<typename TValue>
StrMap<TValue>::StrMap()
{
    m_table = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    if ( m_table == NULL )
    {
        std::bad_alloc e;
        throw e;
    }
}

template<typename TValue>
StrMap<TValue>::~StrMap()
{
    HashTable_Destroy(m_table, StrMapItem_Destroy<TValue>);
    m_table = NULL;
}

template<typename TValue>
bool StrMap<TValue>::HasKey(const std::string &key)
{
    void *pOutData = NULL;
    StrMapItem<TValue> it;
    it.key = key;
    if ( HashTable_Find(m_table, (void *)&it, StrMapItem_Hash<TValue>,
                        StrMapItem_Compare<TValue>, &pOutData) )
    {
        return true;
    }
    else
    {
        return false;
    }
}

template<typename TValue>
void StrMap<TValue>::Clear()
{
    HashTable_Clear(m_table, StrMapItem_Destroy<TValue>);
}

template<typename TValue>
TValue StrMap<TValue>::GetItem(const std::string &key)
{
    void *pOutData = NULL;
    StrMapItem<TValue> it;
    it.key = key;
    if ( HashTable_Find(m_table, (void *)&it, StrMapItem_Hash<TValue>,
                        StrMapItem_Compare<TValue>, &pOutData) )
    {
        return static_cast<StrMapItem<TValue> *>(pOutData)->val;
    }
    else
    {
        StrMapKeyError e(key);
        throw e;
    }
}

template<typename TValue>
void StrMap<TValue>::SetItem(const std::string &key, const TValue &val)
{
    StrMapItem<TValue> *itp = new StrMapItem<TValue>();
    itp->key = key;
    itp->val = val;
    if ( !HashTable_Insert(m_table, (void *)itp,
                           StrMapItem_Hash<TValue>,
                           StrMapItem_Compare<TValue>,
                           StrMapItem_Destroy<TValue>) )
    {
        delete itp;
        itp = NULL;
        std::bad_alloc e;
        throw e;
    }
}

template<typename TValue>
TValue StrMap<TValue>::Pop(const std::string &key)
{
    void *pOutData = NULL;
    StrMapItem<TValue> it;
    it.key = key;
    if ( HashTable_Pop(m_table, (void *)&it, StrMapItem_Hash<TValue>,
                       StrMapItem_Compare<TValue>, &pOutData) )
    {
        it.val = static_cast<StrMapItem<TValue> *>(pOutData)->val;
        delete (StrMapItem<TValue> *)pOutData;
        pOutData = NULL;
        return it.val;
    }
    else
    {
        StrMapKeyError e(key);
        throw e;
    }
}


#endif /* __STRMAP_HPP__ */
