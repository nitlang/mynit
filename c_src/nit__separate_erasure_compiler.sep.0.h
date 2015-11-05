#include "nit.common.h"
#define COLOR_nit__separate_erasure_compiler__ToolContext___opt_erasure 50
extern const char FILE_nit__separate_erasure_compiler[];
#define COLOR_nit__separate_erasure_compiler__ToolContext___opt_rta 51
#define COLOR_nit__separate_erasure_compiler__ToolContext___opt_no_check_erasure_cast 52
#define COLOR_nit__separate_erasure_compiler___ToolContext___standard__kernel__Object__init 141
#define COLOR_nit__toolcontext__ToolContext___option_context 15
extern const char FILE_nit__toolcontext[];
val* NEW_standard__Array(const struct type* type);
extern const struct type type_standard__Array__opts__Option;
val* NEW_standard__NativeArray(int length, const struct type* type);
extern const struct type type_standard__NativeArray__opts__Option;
#define COLOR_standard__array__Array__with_native 58
void opts___opts__OptionContext___add_option(val* self, val* p0);
#define COLOR_nit__separate_erasure_compiler___ToolContext___process_options 144
#define COLOR_nit__abstract_compiler__ToolContext___opt_no_check_all 88
extern const char FILE_nit__abstract_compiler[];
#define COLOR_opts__Option___value 6
#define COLOR_opts__Option__VALUE 0
extern const struct type type_standard__Bool;
extern const char FILE_opts[];
#define COLOR_nit__separate_compiler__ToolContext___opt_no_tag_primitives 58
extern const char FILE_nit__separate_compiler[];
#define COLOR_nit__phase__Phase___toolcontext 0
extern const char FILE_nit__phase[];
val* nit__modelbuilder_base___ToolContext___modelbuilder(val* self);
val* nit__rapid_type_analysis___ModelBuilder___do_rapid_type_analysis(val* self, val* p0);
void nit__separate_erasure_compiler___ModelBuilder___run_separate_erasure_compiler(val* self, val* p0, val* p1);
#include "time_nit.h"
#define COLOR_nit__modelbuilder_base__ModelBuilder___toolcontext 10
extern const char FILE_nit__modelbuilder_base[];
val* standard___standard__NativeString___to_s_with_length(char* self, long p0);
void nit___nit__ToolContext___info(val* self, val* p0, long p1);
val* NEW_nit__SeparateErasureCompiler(const struct type* type);
extern const struct type type_nit__SeparateErasureCompiler;
#define COLOR_nit__abstract_compiler__AbstractCompiler__mainmodule_61d 17
#define COLOR_nit__abstract_compiler__AbstractCompiler__modelbuilder_61d 18
#define COLOR_nit__separate_compiler__SeparateCompiler__runtime_type_analysis_61d 55
#define COLOR_standard__kernel__Object__init 0
void nit___nit__SeparateCompiler___nit__abstract_compiler__AbstractCompiler__do_compilation(val* self);
void nit___nit__SeparateCompiler___nit__abstract_compiler__AbstractCompiler__display_stats(val* self);
extern const struct type type_standard__NativeArray__standard__String;
extern const struct type type_standard__Int;
extern const char FILE_standard__kernel[];
val* standard__string___Int___Object__to_s(long self);
#define COLOR_standard__string__NativeArray__native_to_s 16
void nit__abstract_compiler___ModelBuilder___write_and_make(val* self, val* p0);
#define COLOR_nit__separate_erasure_compiler__SeparateErasureCompiler___class_ids 34
#define COLOR_nit__separate_erasure_compiler__SeparateErasureCompiler___class_colors 35
#define COLOR_nit__separate_erasure_compiler__SeparateErasureCompiler___vt_colors 36
#define COLOR_nit___nit__SeparateErasureCompiler___standard__kernel__Object__init 123
#define COLOR_nit__abstract_compiler__AbstractCompiler___mainmodule 1
val* nit__model___MModule___flatten_mclass_hierarchy(val* self);
val* NEW_standard__HashSet(const struct type* type);
extern const struct type type_standard__HashSet__nit__MClass;
void standard___standard__HashSet___from(val* self, val* p0);
val* NEW_nit__POSetColorer(const struct type* type);
extern const struct type type_nit__POSetColorer__nit__MClass;
void nit___nit__POSetColorer___colorize(val* self, val* p0);
val* nit___nit__POSetColorer___ids(val* self);
val* nit___nit__POSetColorer___colors(val* self);
val* nit___nit__SeparateErasureCompiler___build_class_typing_tables(val* self, val* p0);
#define COLOR_nit__separate_erasure_compiler__SeparateErasureCompiler___class_tables 37
val* NEW_standard__HashMap(const struct type* type);
extern const struct type type_standard__HashMap__nit__MClass__standard__Set__nit__MVirtualTypeProp;
void standard___standard__HashMap___standard__kernel__Object__init(val* self);
val* standard___standard__HashSet___standard__abstract_collection__Collection__iterator(val* self);
#define COLOR_standard__abstract_collection__Iterator__is_ok 16
#define COLOR_standard__abstract_collection__Iterator__item 17
extern const struct type type_standard__HashSet__nit__MVirtualTypeProp;
void standard___standard__HashSet___standard__kernel__Object__init(val* self);
void standard___standard__HashMap___standard__abstract_collection__Map___91d_93d_61d(val* self, val* p0, val* p1);
val* nit__abstract_compiler___MModule___properties(val* self, val* p0);
#define COLOR_standard__abstract_collection__Collection__iterator 25
extern const struct type type_nit__MVirtualTypeProp;
val* standard___standard__HashMap___standard__abstract_collection__MapRead___91d_93d(val* self, val* p0);
#define COLOR_standard__abstract_collection__SimpleCollection__add 45
#define COLOR_standard__abstract_collection__Iterator__next 18
#define COLOR_standard__abstract_collection__Iterator__finish 19
val* NEW_nit__POSetBucketsColorer(const struct type* type);
extern const struct type type_nit__POSetBucketsColorer__nit__MClass__nit__MVirtualTypeProp;
val* nit___nit__POSetColorer___conflicts(val* self);
#define COLOR_nit__coloring__POSetBucketsColorer__poset_61d 16
#define COLOR_nit__coloring__POSetBucketsColorer__conflicts_61d 17
val* nit___nit__POSetBucketsColorer___colorize(val* self, val* p0);
val* nit___nit__SeparateErasureCompiler___build_vt_tables(val* self, val* p0);
#define COLOR_nit__separate_erasure_compiler__SeparateErasureCompiler___vt_tables 38
extern const struct type type_standard__HashMap__nit__MClass__standard__Array__nullable__nit__MPropDef;
extern const struct type type_standard__Array__nullable__nit__MPropDef;
void standard___standard__Array___standard__kernel__Object__init(val* self);
extern const struct type type_standard__Array__nit__MClass;
short int poset___poset__POSet___standard__abstract_collection__Collection__has(val* self, val* p0);
val* nit___nit__MClass___in_hierarchy(val* self, val* p0);
val* poset___poset__POSetElement___greaters(val* self);
#define COLOR_standard__array__Collection__to_a 22
void nit__model___MModule___linearize_mclasses(val* self, val* p0);
val* standard___standard__AbstractArrayRead___standard__abstract_collection__Collection__iterator(val* self);
short int standard__array___standard__array__ArrayIterator___standard__abstract_collection__Iterator__is_ok(val* self);
val* standard__array___standard__array__ArrayIterator___standard__abstract_collection__Iterator__item(val* self);
#define COLOR_standard__abstract_collection__MapRead___91d_93d 19
#define COLOR_standard__array__AbstractArrayRead___length 0
void standard___standard__Array___standard__abstract_collection__Sequence___91d_93d_61d(val* self, long p0, val* p1);
long standard___standard__Int___Discrete__successor(long self, long p0);
#define COLOR_nit__model__MProperty___mpropdefs 12
extern const char FILE_nit__model[];
#define COLOR_nit__model__MPropDef___mclassdef 5
#define COLOR_nit__model__MClassDef___mclass 6
void standard__array___standard__array__ArrayIterator___standard__abstract_collection__Iterator__next(val* self);
void standard__array___standard__array__ArrayIterator___standard__abstract_collection__Iterator__finish(val* self);
extern const struct type type_standard__HashMap__nit__MClass__standard__Array__nullable__nit__MClass;
extern const struct type type_standard__Array__nullable__nit__MClass;
#define COLOR_nit__abstract_compiler__AbstractCompiler___header 7
void nit___nit__CodeWriter___add_decl(val* self, val* p0);
void nit___nit__SeparateCompiler___compile_header_attribute_structs(val* self);
#define COLOR_nit__model__MClass___intro 16
#define COLOR_nit__model__MClassDef___bound_mtype 7
val* nit___nit__MClass___nit__model_base__MEntity__c_name(val* self);
val* nit___nit__SeparateErasureCompiler___nit__abstract_compiler__AbstractCompiler__new_visitor(val* self);
#define COLOR_nit__separate_compiler__SeparateCompiler___runtime_type_analysis 19
#define COLOR_standard__kernel__Object___61d_61d 4
#define COLOR_nit__rapid_type_analysis__RapidTypeAnalysis___live_classes 4
extern const char FILE_nit__rapid_type_analysis[];
short int standard___standard__HashSet___standard__abstract_collection__Collection__has(val* self, val* p0);
short int nit__abstract_compiler___MClassType___MType__is_c_primitive(val* self);
#define COLOR_nit__model__MClass___name 6
void nit___nit__AbstractCompilerVisitor___add_decl(val* self, val* p0);
void nit___nit__AbstractCompiler___provide_declaration(val* self, val* p0, val* p1);
long nit___nit__SeparateCompiler___box_kind_of(val* self, val* p0);
short int nit___nit__SeparateErasureCompiler___build_class_vts_table(val* self, val* p0);
void nit___nit__AbstractCompilerVisitor___require_declaration(val* self, val* p0);
#define COLOR_nit__separate_compiler__SeparateCompiler___method_tables 30
#define COLOR_standard__abstract_collection__MapRead__get_or_null 23
val* standard___standard__Array___standard__abstract_collection__SequenceRead___91d_93d(val* self, long p0);
extern const struct type type_nit__MMethodDef;
#define COLOR_nit__rapid_type_analysis__RapidTypeAnalysis___live_methoddefs 7
#define COLOR_nit__model__MClass___intro_mmodule 5
#define COLOR_standard__string__Object__to_s 3
val* nit__separate_compiler___MMethodDef___virtual_runtime_function(val* self);
val* nit___nit__AbstractRuntimeFunction___c_name(val* self);
val* nit___nit__MPropDef___nit__model_base__MEntity__full_name(val* self);
#define COLOR_nit__model__MClassType___mclass 6
val* nit__abstract_compiler___MClassType___MType__ctype(val* self);
val* nit__abstract_compiler___MClassType___MType__ctype_extern(val* self);
#define COLOR_nit__model_base__MEntity__c_name 16
void nit___nit__AbstractCompilerVisitor___add(val* self, val* p0);
void nit___nit__AbstractCompilerVisitor___add_abort(val* self, val* p0);
val* nit___nit__AbstractCompilerVisitor___new_named_var(val* self, val* p0, val* p1);
#define COLOR_nit__abstract_compiler__RuntimeVariable___is_exact 3
val* nit___nit__AbstractCompilerVisitor___get_name(val* self, val* p0);
#define COLOR_nit__model__MClassType__arguments 54
val* standard___standard__SequenceRead___Collection__first(val* self);
#define COLOR_nit__abstract_compiler__MType__ctype 27
#define COLOR_nit__model__MClass___kind 13
val* nit__model___standard__Sys___extern_kind(val* self);
val* nit__model___MModule___pointer_type(val* self);
#define COLOR_nit__separate_compiler__SeparateCompiler___attr_tables 31
short int standard___standard__Array___standard__kernel__Object___61d_61d(val* self, val* p0);
void nit___nit__AbstractCompiler___generate_init_attr(val* self, val* p0, val* p1, val* p2);
void nit___nit__AbstractCompilerVisitor___set_finalizer(val* self, val* p0);
short int standard___standard__AbstractArrayRead___standard__abstract_collection__Collection__is_empty(val* self);
extern const struct type type_nit__MVirtualTypeDef;
#define COLOR_nit__model__MVirtualTypeDef___bound 13
val* nit___nit__SeparateErasureCompiler___retrieve_vt_bound(val* self, val* p0, val* p1);
extern const struct type type_nit__MNullableType;
#define COLOR_nit__model__MProxyType___mtype 6
extern const struct type type_nit__MClassType;
void standard__file___Sys___print(val* self, val* p0);
extern const struct type type_nit__MVirtualType;
val* nit___nit__MType___anchor_to(val* self, val* p0, val* p1);
extern const struct type type_nit__MParameterType;
void nit___nit__SeparateCompiler___compile_color_consts(val* self, val* p0);
val* NEW_nit__SeparateErasureCompilerVisitor(const struct type* type);
extern const struct type type_nit__SeparateErasureCompilerVisitor;
#define COLOR_nit__abstract_compiler__AbstractCompilerVisitor__compiler_61d 27
#define COLOR_nit__abstract_compiler__AbstractCompiler__VISITOR 0
#define COLOR_standard__abstract_collection__MapRead__iterator 17
#define COLOR_standard__abstract_collection__MapIterator__is_ok 16
#define COLOR_standard__abstract_collection__MapIterator__key 17
#define COLOR_standard__abstract_collection__MapIterator__item 18
#define COLOR_standard__abstract_collection__MapIterator__next 19
#define COLOR_nit___nit__SeparateErasureCompilerVisitor___nit__abstract_compiler__AbstractCompilerVisitor__compile_callsite 106
#define COLOR_nit__typing__CallSite___erasure_cast 8
#define COLOR_nit__abstract_compiler__AbstractCompilerVisitor___compiler 0
#define COLOR_nit__abstract_compiler__AbstractCompiler___modelbuilder 3
#define COLOR_nit__typing__CallSite___msignature 7
extern const char FILE_nit__typing[];
#define COLOR_nit__model__MSignature___return_mtype 7
val* nit___nit__SeparateErasureCompilerVisitor___nit__abstract_compiler__AbstractCompilerVisitor__type_test(val* self, val* p0, val* p1, val* p2);
val* nit___nit__AbstractCompilerVisitor___new_expr(val* self, val* p0, val* p1);
val* nit___nit__RuntimeVariable___standard__string__Object__inspect(val* self);
val* nit___nit__AbstractCompilerVisitor___bool_type(val* self);
val* nit___nit__AbstractCompilerVisitor___new_var(val* self, val* p0);
short int nit___nit__SeparateCompilerVisitor___maybe_null(val* self, val* p0);
#define COLOR_nit__abstract_compiler__AbstractCompilerVisitor___frame 2
#define COLOR_nit__abstract_compiler__StaticFrame___mpropdef 1
#define COLOR_nit__model__MClassDef___mmodule 5
val* nit___nit__MParameterType___MType__resolve_for(val* self, val* p0, val* p1, val* p2, short int p3);
#define COLOR_nit__abstract_compiler__RuntimeVariable___mcasttype 2
short int nit___nit__MType___is_subtype(val* self, val* p0, val* p1, val* p2);
#define COLOR_nit__abstract_compiler__ToolContext___opt_typing_test_metrics 89
#define COLOR_nit__abstract_compiler__AbstractCompiler___count_type_test_skipped 17
#define COLOR_nit__abstract_compiler__RuntimeVariable___mtype 1
#define COLOR_nit__abstract_compiler__MType__is_c_primitive 37
#define COLOR_nit__abstract_compiler__AbstractCompiler___count_type_test_resolved 15
#define COLOR_nit__abstract_compiler__StaticFrame___arguments 3
#define COLOR_nit__model__MVirtualType___mproperty 8
val* nit__separate_compiler___MEntity___const_color(val* self);
val* standard___standard__String___Object__to_s(val* self);
#define COLOR_nit__abstract_compiler__AbstractCompiler___count_type_test_unresolved 16
void nit___nit__AbstractCompilerVisitor___debug(val* self, val* p0);
val* nit___nit__AbstractCompilerVisitor___new_var_extern(val* self, val* p0);
#define COLOR_nit__rapid_type_analysis__RapidTypeAnalysis___live_types 2
val* nit___nit__AbstractCompilerVisitor___mmodule(val* self);
val* nit__model___MModule___native_array_class(val* self);
extern const struct type type_standard__Array__nit__MType;
void standard___standard__Array___with_capacity(val* self, long p0);
void standard___standard__AbstractArray___standard__abstract_collection__Sequence__push(val* self, val* p0);
val* nit___nit__MClass___get_mtype(val* self, val* p0);
void nit___nit__AbstractCompilerVisitor___ret(val* self, val* p0);
