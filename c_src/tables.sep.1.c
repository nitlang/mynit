#include "tables.sep.0.h"
/* method tables#TablesCapable#lexer_goto for (self: TablesCapable, Int, Int): Int */
long tables__TablesCapable__lexer_goto(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = lexer_goto(self, p0, p1);
var = var1;
goto RET_LABEL;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#lexer_goto for (self: Object, Int, Int): Int */
long VIRTUAL_tables__TablesCapable__lexer_goto(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = tables__TablesCapable__lexer_goto(self, p0, p1);
var = var1;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#lexer_accept for (self: TablesCapable, Int): Int */
long tables__TablesCapable__lexer_accept(val* self, long p0) {
long var /* : Int */;
long var1 /* : Int */;
var1 = lexer_accept(self, p0);
var = var1;
goto RET_LABEL;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#lexer_accept for (self: Object, Int): Int */
long VIRTUAL_tables__TablesCapable__lexer_accept(val* self, long p0) {
long var /* : Int */;
long var1 /* : Int */;
var1 = tables__TablesCapable__lexer_accept(self, p0);
var = var1;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#parser_goto for (self: TablesCapable, Int, Int): Int */
long tables__TablesCapable__parser_goto(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = parser_goto(self, p0, p1);
var = var1;
goto RET_LABEL;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#parser_goto for (self: Object, Int, Int): Int */
long VIRTUAL_tables__TablesCapable__parser_goto(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = tables__TablesCapable__parser_goto(self, p0, p1);
var = var1;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#parser_action for (self: TablesCapable, Int, Int): Int */
long tables__TablesCapable__parser_action(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = parser_action(self, p0, p1);
var = var1;
goto RET_LABEL;
RET_LABEL:;
return var;
}
/* method tables#TablesCapable#parser_action for (self: Object, Int, Int): Int */
long VIRTUAL_tables__TablesCapable__parser_action(val* self, long p0, long p1) {
long var /* : Int */;
long var1 /* : Int */;
var1 = tables__TablesCapable__parser_action(self, p0, p1);
var = var1;
RET_LABEL:;
return var;
}
