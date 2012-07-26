#ifndef __CXXPARSETYPE_HPP__
#define __CXXPARSETYPE_HPP__


// 外部用接口
CxxType CxxParseType(CxxTokenReader &tokRdr);

CxxUnitType CxxParseUnitType(CxxTokenReader &tokRdr);

// 返回空字符串表示解析失败
std::string CxxParseUnitType_Int(CxxTokenReader &tokRdr);
std::string CxxParseUnitType_Char(CxxTokenReader &tokRdr);
std::string CxxParseUnitType_Float(CxxTokenReader &tokRdr);


#endif /* __CXXPARSETYPE_HPP__ */
