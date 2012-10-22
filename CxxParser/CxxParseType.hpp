#ifndef __CXXPARSETYPE_HPP__
#define __CXXPARSETYPE_HPP__


// 外部用接口
// 获取类型名
/* 即从 decl_specifier_seq 中提取 CxxType
   CxxType:
         ['::'] [nested_name_specifier] type_name
         ['::'] nested_name_specifier 'template' simple_template_id
 */
/*
   ----- decl_specifier_seq
  /     \
static int * p;
           | `--- direct_declarator  --.
           |                           |--- declarator
           `--- ptr_operator         --/
*/
// 包括 long int 之类的原始类型
CxxType CxxParseType(CxxTokenReader &tokRdr);

CxxUnitType CxxParseUnitType(CxxTokenReader &tokRdr);

// 返回空字符串表示解析失败
std::string CxxParseUnitType_Int(CxxTokenReader &tokRdr);
std::string CxxParseUnitType_Char(CxxTokenReader &tokRdr);
std::string CxxParseUnitType_Float(CxxTokenReader &tokRdr);


#endif /* __CXXPARSETYPE_HPP__ */
