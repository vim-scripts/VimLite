#include <string.h>
#include "StrMap.hpp"

template<typename TValue>
class StrMapItem {
public:
    std::string key;
    TValue val;
};

template<typename TValue>
int StrMapItem_Compare(void *p1, void *p2)
{
    StrMapItem<TValue> *it1 = p1, *it2 = p2;
    return strcmp(it1->key.c_str(), it2->key.c_str());
}

template<typename TValue>
void StrMapItem_Destroy(void *p)
{
    StrMapItem<TValue> *it = p;
    delete it;
}

template<typename TValue>
int StrMapItem_Hash(void *p, size_t count)
{
    StrMapItem<TValue> *it = p;
    return HashString((void *)it->key.c_str(), count);
}

template<typename TValue>
StrMap<TValue>::StrMap()
{
    m_table = HashTable_Create(HASHTABLE_DEFAULT_SIZE);
    if ( m_table )
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
    return it.val;
}

template<typename TValue>
void StrMap<TValue>::SetItem(const std::string &key, const TValue &val)
{
    void *pOutData = NULL;
    StrMapItem<TValue> it;
    it.key = key;
    if ( !HashTable_Insert(m_table, (void *)&it, StrMapItem_Compare<TValue>,
                           StrMapItem_Destroy<TValue>) )
    {
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
    if ( HashTable_Pop(m_table, (void *)&it, StrMapItem_Hash<TValue>, &pOutData) )
    {
        return static_cast<StrMapItem<TValue> *>(pOutData)->val;
    }
    else
    {
        return it.val;
    }
}

