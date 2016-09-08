#include <vector>
#include <iostream>
#include <string>
#include <sstream>
#include "symbolTable.h"
using namespace std;
string itos(int number){
  stringstream ss;
  ss << number; //把int型態變數寫入到stringstream
  string convert_str;
  ss >>  convert_str;  //透過串流運算子寫到string類別即可
  return convert_str;
}
string ctos(string s){
  return s;
}
string convert(int n){
  string tmp;
  switch(n){
    case Boolean:
      tmp="Boolean";
    break;
    case String:
      tmp="String";
    break;
    case Integer:
      tmp="Integer";
    break;
    case Real:
      tmp="Real";
    break;
    case Void:
      tmp="void";
    break;
    default:
    tmp="Unknown";
  }
  return tmp;
}
Entry::Entry(string id){
  returnType=-1;
  isFunc=false;
  isConstant=false;
  isArray=false;
  name=id;
}
Entry::~Entry(){
  vec_type.clear();
}
Table::~Table(){
  for(int i=0;i<vec_entry.size();i++){
    vec_entry[i]->~Entry();
  }
}
Entry* Table::lookup(string s){
  for(int i=0;i<vec_entry.size();i++){
    if(vec_entry[i]->name.compare(s)==0){
      return vec_entry[i];
    }
  }
  return NULL;
}
Entry* Table::insert(string s){
  Entry* temp=this->lookup(s);
  if(temp==NULL){
    vec_entry.push_back(new Entry(s));
    return vec_entry[vec_entry.size()-1];
  }
  else return NULL;
}
void Table::dump(){
  cout<<"------------------------------------\n";
  cout<<"Name         Type \n";
  for(int i=0;i<vec_entry.size();i++){
    cout<<vec_entry[i]->name<<"\t";
    if(vec_entry[i]->isConstant){
      cout<<"const\t";
      if(vec_entry[i]->vec_type[0]==Boolean)cout<<"value: "<<(vec_entry[i]->constI?"true":"false")<<"\t";
      else if(vec_entry[i]->vec_type[0]==Integer)cout<<"value: "<<vec_entry[i]->constI<<"\t";
      else if(vec_entry[i]->vec_type[0]==String)cout<<"value: \""<<vec_entry[i]->constS<<"\"\t";
   }
    if(vec_entry[i]->isFunc){       // is function
      cout<<"retrun Type: "<<convert(vec_entry[i]->returnType)<<"\t";
      if(vec_entry[i]->vec_type.size()>0){
        cout<<"param type: ";
        for(int j=0;j<vec_entry[i]->vec_type.size();j++){
          cout<<convert(vec_entry[i]->vec_type[j])<<"\t";
        }
      }
    }
    else{                       // is variable
      if(vec_entry[i]->vec_type.size()>0){
        cout<<"variable type: ";
        cout<<convert(vec_entry[i]->vec_type[0])<<"\t";
      }
    }
    cout<<endl;
  }
}
void Symbol_Table::dump(){
  cout<<"\n|==============DUMP====================|\n";
  for(int i=0;i<vec_symTab.size();i++){
    cout<<"TABLE #"<<i<<endl;
    vec_symTab[i]->dump();
    cout<<endl;
  }
  cout<<"|================END====================|\n\n";
}
void Symbol_Table::drop(){
  if(vec_symTab.size()>1){
    vec_symTab.pop_back();
  }
}
Entry* Symbol_Table::insert(string s){
  int currentTabId=vec_symTab.size()-1;
  return vec_symTab[currentTabId]->insert(s);
}
Entry* Symbol_Table::lookup(string s){
  int currentTabId=vec_symTab.size()-1;
  Entry* temp=NULL;
  for(;currentTabId>=0;currentTabId--){
    temp=vec_symTab[currentTabId]->lookup(s);
    if(temp!=NULL) return temp;
  }
  return NULL;
}
void Symbol_Table::create(){
  vec_symTab.push_back(new Table());
}
bool Symbol_Table::isBool(string s){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    if(tmp->isFunc){
      if(tmp->returnType==Boolean){
          return true;
      }
    }
    else{
      if(tmp->vec_type.size()==1&&tmp->vec_type[0]==Boolean) return true;
    }
  }
  return false;
}
bool Symbol_Table::isConstant(string s){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    return tmp->isConstant;
  }
  return false;
}
bool Symbol_Table::isConstant(string s,bool val){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->isConstant=val;
    return tmp->isConstant;
  }
  return false;
}
bool Symbol_Table::isFunc(string s){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    return tmp->isFunc;
  }
  return false;
}
bool Symbol_Table::isFunc(string s,bool val){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->isFunc=val;
    return tmp->isFunc;
  }
  return false;
}
Symbol_Table::Symbol_Table(){
  this->create();
}
void Symbol_Table::dumpLookup(string s){
  Entry* tmp=this->lookup(s);
  if(tmp!=NULL){
    cout<<"--------------DUMPLOOKUP------------------"<<endl;
    cout<<"Name: "<<tmp->name<<endl;
    cout<<"isFunc: "<<tmp->isFunc<<endl;
    cout<<"isConstant: "<<tmp->isConstant<<endl;

    cout<<"Return type: "<<convert(tmp->returnType)<<endl;
    for(int i=0;i<tmp->vec_type.size();i++){
      cout<<"Type "<<i<<": "<<convert(tmp->vec_type[i]);
    }
    cout<<endl<<"--------------END DUMPLOOKUP------------------"<<endl;
  }
  else cout<<"Not Found Symbol \""<<s<<"\""<<endl;
}
void Symbol_Table::setRetnType(string s,int t){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->returnType=t;
  }
}
int Symbol_Table::addType(string s,int t){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->vec_type.push_back(t);
    return 0;
  }
  else return 1;
}
int Symbol_Table::getType(string s,int i){
   Entry* tmp=lookup(s);
   if(tmp!=NULL&&tmp->vec_type.size()>i&&i>=0){
     return tmp->vec_type[i];
   }
   else return -1;
}
int Symbol_Table::getRetnType(string s){
   Entry* tmp=lookup(s);
   if(tmp!=NULL&&tmp->isFunc){
     return tmp->returnType;
   }
   else return -1;
}
bool Symbol_Table::isArray(string s){
   Entry* tmp=lookup(s);
   if(tmp!=NULL){
     return tmp->isArray;
   }
   return false;
}
bool Symbol_Table::isArray(string s,bool val){
   Entry* tmp=lookup(s);
   if(tmp!=NULL){
     tmp->isArray=val;
     return tmp->isArray;
   }
   return false;
}
int Symbol_Table::isGlobal(){
  if(vec_symTab.size()==1){
    return 1;
  }
  return 0;
}
int Table::lookupL(string s){
  for(int i=0;i<vec_entry.size();i++){
    if(vec_entry[i]->name.compare(s)==0){
      return i;
    }
  }
  return -1;
}

string Symbol_Table::read(string s,string classN){
  string stamt;
  //"getstatic int "

  //"iload 0"
  Entry* temp=lookup(s);
  if(temp==NULL) return "";

  int currentTabId=vec_symTab.size();
  currentTabId--;
  int index=-1;
  for(;currentTabId>=1;currentTabId--){
    index=vec_symTab[currentTabId]->lookupL(s);
    if(index>=0) break;
  }
  //start generating statement
  if(temp->isFunc){ //function
    stamt+="invokestatic ";
    if(temp->returnType==Integer||temp->returnType==Boolean) stamt+="int ";
    else if (temp->returnType==Void) stamt+="void ";
    else return "";
    stamt+=classN+"."+s+"(";
    int size=temp->vec_type.size();
    for(int i=0;i<size-1;i++){
      switch(temp->vec_type[i]){
        case Integer:
        case Boolean:
        stamt+="int, ";
        break;
        default:
          return "";
      }
    }
    if(size>0){
      if(temp->vec_type[size-1]==Integer||
      temp->vec_type[size-1]==Boolean){
        stamt+="int";
      }
      else{
        return "";
      }
    }
    stamt+=")";
  }
  else if (temp->isConstant){ //constant
    switch(temp->vec_type[0]){
      case Integer:
        stamt="sipush "+itos(temp->constI);
      break;
      case String:
        stamt="ldc \""+temp->constS+"\"";
      break;
      case Boolean:
        stamt="iconst_"+itos(temp->constI);
      break;
      default:
      return "";
    }
  }
  else if(index>=0){  //loacl variable
      if(temp->vec_type[0]==Integer||temp->vec_type[0]==Boolean)
        stamt="iload "+itos(index);
      else return "";
  }
  else{         //global variable
    if(temp->vec_type[0]==Integer||temp->vec_type[0]==Boolean)
      stamt="getstatic int "+classN+"."+s;
    else return "";
  }
  return stamt;
}
string Symbol_Table::write(string s,string classN){
  string stamt;
  Entry* temp=lookup(s);
  if(temp==NULL) return "";

  int currentTabId=vec_symTab.size();
  currentTabId--;
  int index=-1;
  for(;currentTabId>=1;currentTabId--){
    index=vec_symTab[currentTabId]->lookupL(s);
    if(index>=0) break;
  }
  if(index>=0){  //loacl variable
      if(temp->vec_type[0]==Integer||temp->vec_type[0]==Boolean)
        stamt="istore "+itos(index);
      else return "";
  }
  else{         //global variable
    if(temp->vec_type[0]==Integer||temp->vec_type[0]==Boolean)
      stamt="putstatic int "+classN+"."+s;
    else return "";
  }
//"putstatic int example.c"
//"istore 2"
  return stamt;
}
void Symbol_Table::setConstI(string s,int t){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->constI=t;
  }
}
void Symbol_Table::setConstS(string s,string c){
  Entry* tmp=lookup(s);
  if(tmp!=NULL){
    tmp->constS=c;
  }
}
int Symbol_Table::next(){
  int tableSize=vec_symTab.size();
  if(tableSize>1){
    return vec_symTab[tableSize-1]->vec_entry.size();
  }
  return -1;
}
string Symbol_Table::funcDeclare(string s){
  string stamt;
  //method public static int "+ctos($3)+"("
  Entry* temp=lookup(s);
  if(temp==NULL||(temp->returnType!=Boolean&&temp->returnType!=Integer&&temp->returnType!=Void)) return "";
  if(temp->returnType!=Void)stamt+="method public static int "+s+"(";
  else stamt+="method public static void "+s+"(";
  int size=temp->vec_type.size();
  for(int i=0;i<size-1;i++){
    switch(temp->vec_type[i]){
      case Integer:
      case Boolean:
      stamt+="int, ";
      break;
      default:
        return "";
    }
  }
  if(size>0){
    if(temp->vec_type[size-1]==Integer||
    temp->vec_type[size-1]==Boolean){
      stamt+="int";
    }
    else{
      return "";
    }
  }
  stamt+=")\n";
  stamt+="max_stack 15\nmax_locals 15\n{";
  return stamt;
}
// int main(){
//   Symbol_Table table;
//   table.insert("Gaa");
//    table.addType("Gaa",Integer);
//    table.addType("Gaa",Integer);
//    table.addType("Gaa",Integer);
//    table.setRetnType("Gaa",Integer);
//    table.isFunc("Gaa",true);
//   // table.insert("Gbb");
//   // table.create();
//   // table.insert("Laa");
//   // table.addType("Laa",Integer);
//   // table.insert("Lbb");
//    cout<<"get Gaa\n"<<table.read("Gaa","example")<<endl;
//   // cout<<"get Laa "<<table.read("Laa","example")<<endl;
//   // cout<<"save Gaa "<<table.write("Gaa","example")<<endl;
//   // cout<<"save Laa "<<table.write("Laa","example")<<endl;
//   string a="adsfadf";
//   string b="123132";
//   a=a+b;
//   cout<<a<<endl;
// }
