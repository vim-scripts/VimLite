#!/usr/bin/env python
# -*- encoding:utf-8 -*-

from xml.dom import minidom

# 非递归地从 node 节点的子节点中查找标签名为 tagName 的元素节点
# 返回标签名为 tagName 的元素节点列表
def GetElementsByTagNameNR(node, tagName):
    li = []
    for i in node.childNodes:
        if i.nodeType == i.ELEMENT_NODE \
           and i.tagName == tagName:
            li.append(i)
    return li

# 非递归地从 node 节点的子节点中查找标签名为 tagName 的元素节点的指定属性值
# 返回属性值列表
def GetChildElemAttrValuesNR(node, tagName, attrName):
    li = []
    lNode = GetElementsByTagNameNR(node, tagName)
    for i in lNode:
        if i.hasAttribute(attrName):
            li.append(i.attributes[attrName].value)
    return li



#'''用于兼容 codelite 项目文件的 xml 工具集'''
    
def FindNodeByName(parent, tagName, name):
    '''Find a child node by name by iterating the parent children. 
    NULL if no childs exist
    
    parent: the parent node whom to be searched
    tagName: the element tag name
    name: the element 'Name' property value to search'''
    if not parent:
        return None
    
    for i in parent.childNodes:
        if i.nodeType == i.ELEMENT_NODE and i.tagName == tagName \
                       and i.getAttribute('Name') == name:
                return i
    
    return None

def FindFirstByTagName(parent, tagName):
    '''Find the first child node of parent with a given name'''
    for i in parent.childNodes:
        if i.nodeType == i.ELEMENT_NODE and i.tagName == tagName:
            return i

def FindLastByTagName(parent, tagName):
    # FIXME: 可优化
    node = None
    for i in parent.childNodes:
        if i.nodeType == i.ELEMENT_NODE and i.tagName == tagName:
            node = i
    return node

def UpdateProperty(node, name, value):
    node.setAttribute(name, value)

def SetNodeContent(node, text):
    '''Set the content of node. This function replaces any existing content of node
    text node?'''
    contentNode = None
    for i in node.childNodes:
        if i.nodeType == i.TEXT_NODE or i.nodeType == CDATA_SECTION_NODE:
            contentNode = i
            break
    
    if contentNode:
        node.removeChild(contentNode)
    
    if text:
        contentNode = minidom.Document().createTextNode(text)
        node.appendChild(contentNode)

def ReadString(node, attrName, defaultValue = ''):
    ret = node.getAttribute(attrName).encode('utf-8')
    if not ret:
        ret = defaultValue
    return ret

def ReadStringIfExists(node, attrName):
    ret = node.getAttribute(attrName).encode('utf-8')
    if ret:
        return True, ret
    else:
        return False, ret

def ReadLong(node, attrName, defaultValue = -1):
    ret = node.getAttribute(attrName).encode('utf-8')
    if not ret:
        return defaultValue
    
    if ret.startswith('"'):
        ret = ret[1:]
        
    if ret.endswith('"'):
        ret = ret[:-1]
        
    if ret.isdigit():
        return int(ret)
    else:
        return defaultValue

def ReadLongIfExists(node, attrName):
    ret = node.getAttribute(attrName).encode('utf-8')
    if not ret:
        return False, defaultValue
    
    if ret.startswith('"'):
        ret = ret[1:]
        
    if ret.endswith('"'):
        ret = ret[:-1]
        
    if ret.isdigit():
        return True, int(ret)
    else:
        return False, int(ret)

def ReadBool(node, attrName, defaultValue = False):
    ret = node.getAttribute(attrName).encode('utf-8')
    if not ret:
        return defaultValue
    
    if ret.lower() == 'yes':
        return True
    else:
        return False

def ReadBoolIfExists(node, attrName):
    ret = node.getAttribute(attrName).encode('utf-8')
    if not ret:
        return False, False
    
    if ret.lower() == 'yes':
        return True, True
    else:
        return True, False
    pass

def RemoveAllChildren(node):
    '''Remove all children of xml node'''
    while node.lastChild:
        node.removeChild(node.lastChild)

def StaticReadObject(node, name, serialObj):
    pass

def StaticWriteObject(node, name, serialObj):
    pass

def SetCDATANodeContent(node, text):
    pass

def GetNodeContent(node):
    '''获取节点包含的文本'''
    for i in node.childNodes:
        if i.nodeType == i.TEXT_NODE:
            return i.data
    return ''

def GetFirstChildElement(node):
    for i in node.childNodes:
        if i.nodeType == i.ELEMENT_NODE:
            return i
    return None

def GetRoot(dom):
    return GetFirstChildElement(dom)

def PrettifyDoc(doc):
    doc = minidom.parseString(ToPrettyXmlString(doc))
    return doc

def ToPrettyXmlString(doc):
    try:
        from lxml import etree
    except ImportError:
        return doc.toxml('utf-8')
    parser = etree.XMLParser(remove_blank_text = True)
    root = etree.XML(doc.toxml(), parser)
    return etree.tostring(root, 
                          encoding = 'utf-8', 
                          xml_declaration = True, 
                          pretty_print = True)

if __name__ == '__main__':
    s = '''
<ref id="bit">
  <p>0</p>
  <p>1</p>
</ref>'''
    n = minidom.parseString(s)
    print n.toxml()
    node = n.firstChild.firstChild
    print n.firstChild.childNodes[1]
    print GetRoot(n.firstChild)
    
    
