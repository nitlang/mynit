# Raw AST node hierarchy.
# This file was generated by SableCC (http://www.sablecc.org/). 
package parser_abs

# Root of the AST hierarchy
abstract class PNode
end

# Ancestor of all tokens
abstract class Token
special PNode
end

# Ancestor of all productions
abstract class Prod
special PNode
end
class TEol
special Token
end
class TComment
special Token
end
class TKwpackage
special Token
end
class TKwimport
special Token
end
class TKwclass
special Token
end
class TKwabstract
special Token
end
class TKwinterface
special Token
end
class TKwuniversal
special Token
end
class TKwspecial
special Token
end
class TKwend
special Token
end
class TKwmeth
special Token
end
class TKwtype
special Token
end
class TKwattr
special Token
end
class TKwinit
special Token
end
class TKwredef
special Token
end
class TKwis
special Token
end
class TKwdo
special Token
end
class TKwreadable
special Token
end
class TKwwritable
special Token
end
class TKwvar
special Token
end
class TKwintern
special Token
end
class TKwextern
special Token
end
class TKwprotected
special Token
end
class TKwprivate
special Token
end
class TKwintrude
special Token
end
class TKwif
special Token
end
class TKwthen
special Token
end
class TKwelse
special Token
end
class TKwwhile
special Token
end
class TKwfor
special Token
end
class TKwin
special Token
end
class TKwand
special Token
end
class TKwor
special Token
end
class TKwnot
special Token
end
class TKwreturn
special Token
end
class TKwcontinue
special Token
end
class TKwbreak
special Token
end
class TKwabort
special Token
end
class TKwassert
special Token
end
class TKwnew
special Token
end
class TKwisa
special Token
end
class TKwonce
special Token
end
class TKwsuper
special Token
end
class TKwself
special Token
end
class TKwtrue
special Token
end
class TKwfalse
special Token
end
class TKwnull
special Token
end
class TKwas
special Token
end
class TKwwith
special Token
end
class TKwnullable
special Token
end
class TKwisset
special Token
end
class TOpar
special Token
end
class TCpar
special Token
end
class TObra
special Token
end
class TCbra
special Token
end
class TComma
special Token
end
class TColumn
special Token
end
class TQuad
special Token
end
class TAssign
special Token
end
class TPluseq
special Token
end
class TMinuseq
special Token
end
class TDotdotdot
special Token
end
class TDotdot
special Token
end
class TDot
special Token
end
class TPlus
special Token
end
class TMinus
special Token
end
class TStar
special Token
end
class TSlash
special Token
end
class TPercent
special Token
end
class TEq
special Token
end
class TNe
special Token
end
class TLt
special Token
end
class TLe
special Token
end
class TGt
special Token
end
class TGe
special Token
end
class TStarship
special Token
end
class TClassid
special Token
end
class TId
special Token
end
class TAttrid
special Token
end
class TNumber
special Token
end
class TFloat
special Token
end
class TChar
special Token
end
class TString
special Token
end
class TStartString
special Token
end
class TMidString
special Token
end
class TEndString
special Token
end
class EOF 
special Token
private init noinit do end
end
class PError
special EOF
private init noinit do end
end

class PModule special Prod end
class PPackagedecl special Prod end
class PImport special Prod end
class PVisibility special Prod end
class PClassdef special Prod end
class PClasskind special Prod end
class PFormaldef special Prod end
class PSuperclass special Prod end
class PPropdef special Prod end
class PAble special Prod end
class PMethid special Prod end
class PSignature special Prod end
class PParam special Prod end
class PClosureDecl special Prod end
class PType special Prod end
class PExpr special Prod end
class PAssignOp special Prod end
class PClosureDef special Prod end
class PQualified special Prod end
class PDoc special Prod end

class AModule
special PModule
    readable writable attr _n_packagedecl: nullable PPackagedecl = null
    readable writable attr _n_imports: List[PImport] = new List[PImport]
    readable writable attr _n_classdefs: List[PClassdef] = new List[PClassdef]
end
class APackagedecl
special PPackagedecl
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwpackage: TKwpackage
    readable writable attr _n_id: TId
end
class AImport
special PImport
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwimport: TKwimport
    readable writable attr _n_id: TId
end
class ANoImport
special PImport
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwimport: TKwimport
    readable writable attr _n_kwend: TKwend
end
class APublicVisibility
special PVisibility
end
class APrivateVisibility
special PVisibility
    readable writable attr _n_kwprivate: TKwprivate
end
class AProtectedVisibility
special PVisibility
    readable writable attr _n_kwprotected: TKwprotected
end
class AIntrudeVisibility
special PVisibility
    readable writable attr _n_kwintrude: TKwintrude
end
class AClassdef
special PClassdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_classkind: PClasskind
    readable writable attr _n_id: nullable TClassid = null
    readable writable attr _n_formaldefs: List[PFormaldef] = new List[PFormaldef]
    readable writable attr _n_superclasses: List[PSuperclass] = new List[PSuperclass]
    readable writable attr _n_propdefs: List[PPropdef] = new List[PPropdef]
end
class ATopClassdef
special PClassdef
    readable writable attr _n_propdefs: List[PPropdef] = new List[PPropdef]
end
class AMainClassdef
special PClassdef
    readable writable attr _n_propdefs: List[PPropdef] = new List[PPropdef]
end
class AConcreteClasskind
special PClasskind
    readable writable attr _n_kwclass: TKwclass
end
class AAbstractClasskind
special PClasskind
    readable writable attr _n_kwabstract: TKwabstract
    readable writable attr _n_kwclass: TKwclass
end
class AInterfaceClasskind
special PClasskind
    readable writable attr _n_kwinterface: TKwinterface
end
class AUniversalClasskind
special PClasskind
    readable writable attr _n_kwuniversal: TKwuniversal
end
class AFormaldef
special PFormaldef
    readable writable attr _n_id: TClassid
    readable writable attr _n_type: nullable PType = null
end
class ASuperclass
special PSuperclass
    readable writable attr _n_kwspecial: TKwspecial
    readable writable attr _n_type: PType
end
class AAttrPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_readable: nullable PAble = null
    readable writable attr _n_writable: nullable PAble = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwattr: nullable TKwattr = null
    readable writable attr _n_kwvar: nullable TKwvar = null
    readable writable attr _n_id: TAttrid
    readable writable attr _n_type: nullable PType = null
    readable writable attr _n_expr: nullable PExpr = null
end
class AMethPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_methid: PMethid
    readable writable attr _n_signature: PSignature
end
class ADeferredMethPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwmeth: TKwmeth
    readable writable attr _n_methid: PMethid
    readable writable attr _n_signature: PSignature
end
class AInternMethPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwmeth: TKwmeth
    readable writable attr _n_methid: PMethid
    readable writable attr _n_signature: PSignature
end
class AExternMethPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwmeth: TKwmeth
    readable writable attr _n_methid: PMethid
    readable writable attr _n_signature: PSignature
    readable writable attr _n_extern: nullable TString = null
end
class AConcreteMethPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwmeth: TKwmeth
    readable writable attr _n_methid: PMethid
    readable writable attr _n_signature: PSignature
    readable writable attr _n_block: nullable PExpr = null
end
class AConcreteInitPropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwinit: TKwinit
    readable writable attr _n_methid: nullable PMethid = null
    readable writable attr _n_signature: PSignature
    readable writable attr _n_block: nullable PExpr = null
end
class AMainMethPropdef
special PPropdef
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_block: nullable PExpr = null
end
class ATypePropdef
special PPropdef
    readable writable attr _n_doc: nullable PDoc = null
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_visibility: PVisibility
    readable writable attr _n_kwtype: TKwtype
    readable writable attr _n_id: TClassid
    readable writable attr _n_type: PType
end
class AReadAble
special PAble
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_kwreadable: TKwreadable
end
class AWriteAble
special PAble
    readable writable attr _n_kwredef: nullable TKwredef = null
    readable writable attr _n_kwwritable: TKwwritable
end
class AIdMethid
special PMethid
    readable writable attr _n_id: TId
end
class APlusMethid
special PMethid
    readable writable attr _n_plus: TPlus
end
class AMinusMethid
special PMethid
    readable writable attr _n_minus: TMinus
end
class AStarMethid
special PMethid
    readable writable attr _n_star: TStar
end
class ASlashMethid
special PMethid
    readable writable attr _n_slash: TSlash
end
class APercentMethid
special PMethid
    readable writable attr _n_percent: TPercent
end
class AEqMethid
special PMethid
    readable writable attr _n_eq: TEq
end
class ANeMethid
special PMethid
    readable writable attr _n_ne: TNe
end
class ALeMethid
special PMethid
    readable writable attr _n_le: TLe
end
class AGeMethid
special PMethid
    readable writable attr _n_ge: TGe
end
class ALtMethid
special PMethid
    readable writable attr _n_lt: TLt
end
class AGtMethid
special PMethid
    readable writable attr _n_gt: TGt
end
class ABraMethid
special PMethid
    readable writable attr _n_obra: TObra
    readable writable attr _n_cbra: TCbra
end
class AStarshipMethid
special PMethid
    readable writable attr _n_starship: TStarship
end
class AAssignMethid
special PMethid
    readable writable attr _n_id: TId
    readable writable attr _n_assign: TAssign
end
class ABraassignMethid
special PMethid
    readable writable attr _n_obra: TObra
    readable writable attr _n_cbra: TCbra
    readable writable attr _n_assign: TAssign
end
class ASignature
special PSignature
    readable writable attr _n_params: List[PParam] = new List[PParam]
    readable writable attr _n_type: nullable PType = null
    readable writable attr _n_closure_decls: List[PClosureDecl] = new List[PClosureDecl]
end
class AParam
special PParam
    readable writable attr _n_id: TId
    readable writable attr _n_type: nullable PType = null
    readable writable attr _n_dotdotdot: nullable TDotdotdot = null
end
class AClosureDecl
special PClosureDecl
    readable writable attr _n_kwwith: TKwwith
    readable writable attr _n_kwbreak: nullable TKwbreak = null
    readable writable attr _n_id: TId
    readable writable attr _n_signature: PSignature
    readable writable attr _n_expr: nullable PExpr = null
end
class AType
special PType
    readable writable attr _n_kwnullable: nullable TKwnullable = null
    readable writable attr _n_id: TClassid
    readable writable attr _n_types: List[PType] = new List[PType]
end
class ABlockExpr
special PExpr
    readable writable attr _n_expr: List[PExpr] = new List[PExpr]
end
class AVardeclExpr
special PExpr
    readable writable attr _n_kwvar: TKwvar
    readable writable attr _n_id: TId
    readable writable attr _n_type: nullable PType = null
    readable writable attr _n_assign: nullable TAssign = null
    readable writable attr _n_expr: nullable PExpr = null
end
class AReturnExpr
special PExpr
    readable writable attr _n_kwreturn: TKwreturn
    readable writable attr _n_expr: nullable PExpr = null
end
class ABreakExpr
special PExpr
    readable writable attr _n_kwbreak: TKwbreak
    readable writable attr _n_expr: nullable PExpr = null
end
class AAbortExpr
special PExpr
    readable writable attr _n_kwabort: TKwabort
end
class AContinueExpr
special PExpr
    readable writable attr _n_kwcontinue: TKwcontinue
    readable writable attr _n_expr: nullable PExpr = null
end
class ADoExpr
special PExpr
    readable writable attr _n_kwdo: TKwdo
    readable writable attr _n_block: nullable PExpr = null
end
class AIfExpr
special PExpr
    readable writable attr _n_kwif: TKwif
    readable writable attr _n_expr: PExpr
    readable writable attr _n_then: nullable PExpr = null
    readable writable attr _n_else: nullable PExpr = null
end
class AIfexprExpr
special PExpr
    readable writable attr _n_kwif: TKwif
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwthen: TKwthen
    readable writable attr _n_then: PExpr
    readable writable attr _n_kwelse: TKwelse
    readable writable attr _n_else: PExpr
end
class AWhileExpr
special PExpr
    readable writable attr _n_kwwhile: TKwwhile
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwdo: TKwdo
    readable writable attr _n_block: nullable PExpr = null
end
class AForExpr
special PExpr
    readable writable attr _n_kwfor: TKwfor
    readable writable attr _n_id: TId
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwdo: TKwdo
    readable writable attr _n_block: nullable PExpr = null
end
class AAssertExpr
special PExpr
    readable writable attr _n_kwassert: TKwassert
    readable writable attr _n_id: nullable TId = null
    readable writable attr _n_expr: PExpr
end
class AOnceExpr
special PExpr
    readable writable attr _n_kwonce: TKwonce
    readable writable attr _n_expr: PExpr
end
class ASendExpr
special PExpr
    readable writable attr _n_expr: PExpr
end
class ABinopExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AOrExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AAndExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ANotExpr
special PExpr
    readable writable attr _n_kwnot: TKwnot
    readable writable attr _n_expr: PExpr
end
class AEqExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AEeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ANeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ALtExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ALeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AGtExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AGeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AIsaExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_type: PType
end
class APlusExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AMinusExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AStarshipExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AStarExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ASlashExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class APercentExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AUminusExpr
special PExpr
    readable writable attr _n_minus: TMinus
    readable writable attr _n_expr: PExpr
end
class ANewExpr
special PExpr
    readable writable attr _n_kwnew: TKwnew
    readable writable attr _n_type: PType
    readable writable attr _n_id: nullable TId = null
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
end
class AAttrExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TAttrid
end
class AAttrAssignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TAttrid
    readable writable attr _n_assign: TAssign
    readable writable attr _n_value: PExpr
end
class AAttrReassignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TAttrid
    readable writable attr _n_assign_op: PAssignOp
    readable writable attr _n_value: PExpr
end
class ACallExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_closure_defs: List[PClosureDef] = new List[PClosureDef]
end
class ACallAssignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_assign: TAssign
    readable writable attr _n_value: PExpr
end
class ACallReassignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_assign_op: PAssignOp
    readable writable attr _n_value: PExpr
end
class ASuperExpr
special PExpr
    readable writable attr _n_qualified: nullable PQualified = null
    readable writable attr _n_kwsuper: TKwsuper
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
end
class AInitExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwinit: TKwinit
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
end
class ABraExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_closure_defs: List[PClosureDef] = new List[PClosureDef]
end
class ABraAssignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_assign: TAssign
    readable writable attr _n_value: PExpr
end
class ABraReassignExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_assign_op: PAssignOp
    readable writable attr _n_value: PExpr
end
class AClosureCallExpr
special PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_args: List[PExpr] = new List[PExpr]
    readable writable attr _n_closure_defs: List[PClosureDef] = new List[PClosureDef]
end
class AVarExpr
special PExpr
    readable writable attr _n_id: TId
end
class AVarAssignExpr
special PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_assign: TAssign
    readable writable attr _n_value: PExpr
end
class AVarReassignExpr
special PExpr
    readable writable attr _n_id: TId
    readable writable attr _n_assign_op: PAssignOp
    readable writable attr _n_value: PExpr
end
class ARangeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class ACrangeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AOrangeExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_expr2: PExpr
end
class AArrayExpr
special PExpr
    readable writable attr _n_exprs: List[PExpr] = new List[PExpr]
end
class ASelfExpr
special PExpr
    readable writable attr _n_kwself: TKwself
end
class AImplicitSelfExpr
special PExpr
end
class ATrueExpr
special PExpr
    readable writable attr _n_kwtrue: TKwtrue
end
class AFalseExpr
special PExpr
    readable writable attr _n_kwfalse: TKwfalse
end
class ANullExpr
special PExpr
    readable writable attr _n_kwnull: TKwnull
end
class AIntExpr
special PExpr
    readable writable attr _n_number: TNumber
end
class AFloatExpr
special PExpr
    readable writable attr _n_float: TFloat
end
class ACharExpr
special PExpr
    readable writable attr _n_char: TChar
end
class AStringExpr
special PExpr
    readable writable attr _n_string: TString
end
class AStartStringExpr
special PExpr
    readable writable attr _n_string: TStartString
end
class AMidStringExpr
special PExpr
    readable writable attr _n_string: TMidString
end
class AEndStringExpr
special PExpr
    readable writable attr _n_string: TEndString
end
class ASuperstringExpr
special PExpr
    readable writable attr _n_exprs: List[PExpr] = new List[PExpr]
end
class AParExpr
special PExpr
    readable writable attr _n_expr: PExpr
end
class AAsCastExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwas: TKwas
    readable writable attr _n_type: PType
end
class AAsNotnullExpr
special PExpr
    readable writable attr _n_expr: PExpr
    readable writable attr _n_kwas: TKwas
    readable writable attr _n_kwnot: TKwnot
    readable writable attr _n_kwnull: TKwnull
end
class AIssetAttrExpr
special PExpr
    readable writable attr _n_kwisset: TKwisset
    readable writable attr _n_expr: PExpr
    readable writable attr _n_id: TAttrid
end
class APlusAssignOp
special PAssignOp
    readable writable attr _n_pluseq: TPluseq
end
class AMinusAssignOp
special PAssignOp
    readable writable attr _n_minuseq: TMinuseq
end
class AClosureDef
special PClosureDef
    readable writable attr _n_kwwith: TKwwith
    readable writable attr _n_id: List[TId] = new List[TId]
    readable writable attr _n_kwdo: TKwdo
    readable writable attr _n_expr: nullable PExpr = null
end
class AQualified
special PQualified
    readable writable attr _n_id: List[TId] = new List[TId]
    readable writable attr _n_classid: nullable TClassid = null
end
class ADoc
special PDoc
    readable writable attr _n_comment: List[TComment] = new List[TComment]
end

class Start
special Prod
    readable writable attr _n_base: nullable PModule 
    readable writable attr _n_eof: EOF 
end
