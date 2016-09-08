
#include <vector>
#include <iostream>
#include <string>
#define Boolean 261
#define String 281
#define Integer 271
#define Real 272
#define Void 285
using namespace std;
string itos(int number);
string ctos(string s);
string convert(int n);
class Entry{
public:
  ~Entry();
  Entry(string id);
  int returnType;
  bool isFunc;
  bool isArray;
  bool isConstant;
  string constS;
  int constI;
  double constR;
  string name;
  vector<int> vec_type;
};

class Table{
public:
  ~Table();
  Entry* lookup(string s);
  int lookupL(string s);
  Entry* insert(string s);
  void dump();
  vector<Entry*> vec_entry;
};
class Symbol_Table{
public:
  Symbol_Table();
  string read(string s,string classN);
  string write(string s,string classN);
  void create();
  bool isBool(string s);
  bool isConstant(string s);
  bool isFunc(string s);
  bool isConstant(string s,bool val);
  bool isFunc(string s,bool val);
  bool isArray(string s,bool val);
  bool isArray(string s);
  Entry* lookup(string s);
  Entry* insert(string s);
  void dumpLookup(string s);
  void setRetnType(string s,int t);
  int addType(string s,int t);//0 success 1 fail
  int getType(string s,int i);
  int getRetnType(string s);
  void drop();
  void dump();
  int isGlobal();
  void setConstI(string s,int t);
  void setConstS(string s,string c);
  int next();
  string funcDeclare(string s);
  vector<Table*> vec_symTab;


};
