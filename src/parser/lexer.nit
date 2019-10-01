# Lexer and its tokens.
# This file was generated by SableCC (http://www.sablecc.org/).
module lexer is generated, no_warning("missing-doc")

intrude import parser_nodes
intrude import lexer_work
private import tables

redef class TEol
    redef fun parser_index: Int
    do
	return 0
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TComment
    redef fun parser_index: Int
    do
	return 1
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwpackage
    redef fun parser_index: Int
    do
	return 2
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwmodule
    redef fun parser_index: Int
    do
	return 3
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwimport
    redef fun parser_index: Int
    do
	return 4
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwclass
    redef fun parser_index: Int
    do
	return 5
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwabstract
    redef fun parser_index: Int
    do
	return 6
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwinterface
    redef fun parser_index: Int
    do
	return 7
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwenum
    redef fun parser_index: Int
    do
	return 8
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwsubset
    redef fun parser_index: Int
    do
	return 9
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwend
    redef fun parser_index: Int
    do
	return 10
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwmeth
    redef fun parser_index: Int
    do
	return 11
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwtype
    redef fun parser_index: Int
    do
	return 12
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwinit
    redef fun parser_index: Int
    do
	return 13
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwredef
    redef fun parser_index: Int
    do
	return 14
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwis
    redef fun parser_index: Int
    do
	return 15
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwdo
    redef fun parser_index: Int
    do
	return 16
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwvar
    redef fun parser_index: Int
    do
	return 17
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwextern
    redef fun parser_index: Int
    do
	return 18
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwpublic
    redef fun parser_index: Int
    do
	return 19
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwprotected
    redef fun parser_index: Int
    do
	return 20
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwprivate
    redef fun parser_index: Int
    do
	return 21
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwintrude
    redef fun parser_index: Int
    do
	return 22
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwif
    redef fun parser_index: Int
    do
	return 23
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwthen
    redef fun parser_index: Int
    do
	return 24
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwelse
    redef fun parser_index: Int
    do
	return 25
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwwhile
    redef fun parser_index: Int
    do
	return 26
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwloop
    redef fun parser_index: Int
    do
	return 27
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwfor
    redef fun parser_index: Int
    do
	return 28
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwin
    redef fun parser_index: Int
    do
	return 29
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwand
    redef fun parser_index: Int
    do
	return 30
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwor
    redef fun parser_index: Int
    do
	return 31
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwnot
    redef fun parser_index: Int
    do
	return 32
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwimplies
    redef fun parser_index: Int
    do
	return 33
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwreturn
    redef fun parser_index: Int
    do
	return 34
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwcontinue
    redef fun parser_index: Int
    do
	return 35
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwbreak
    redef fun parser_index: Int
    do
	return 36
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwabort
    redef fun parser_index: Int
    do
	return 37
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwassert
    redef fun parser_index: Int
    do
	return 38
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwnew
    redef fun parser_index: Int
    do
	return 39
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwisa
    redef fun parser_index: Int
    do
	return 40
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwonce
    redef fun parser_index: Int
    do
	return 41
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwsuper
    redef fun parser_index: Int
    do
	return 42
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwself
    redef fun parser_index: Int
    do
	return 43
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwtrue
    redef fun parser_index: Int
    do
	return 44
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwfalse
    redef fun parser_index: Int
    do
	return 45
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwnull
    redef fun parser_index: Int
    do
	return 46
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwas
    redef fun parser_index: Int
    do
	return 47
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwnullable
    redef fun parser_index: Int
    do
	return 48
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwisset
    redef fun parser_index: Int
    do
	return 49
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwlabel
    redef fun parser_index: Int
    do
	return 50
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwwith
    redef fun parser_index: Int
    do
	return 51
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwdebug
    redef fun parser_index: Int
    do
	return 52
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwyield
    redef fun parser_index: Int
    do
	return 53
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TKwcatch
    redef fun parser_index: Int
    do
	return 54
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TOpar
    redef fun parser_index: Int
    do
	return 55
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TCpar
    redef fun parser_index: Int
    do
	return 56
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TObra
    redef fun parser_index: Int
    do
	return 57
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TCbra
    redef fun parser_index: Int
    do
	return 58
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TObrace
    redef fun parser_index: Int
    do
	return 59
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TCbrace
    redef fun parser_index: Int
    do
	return 60
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TComma
    redef fun parser_index: Int
    do
	return 61
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TColumn
    redef fun parser_index: Int
    do
	return 62
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TQuad
    redef fun parser_index: Int
    do
	return 63
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TAssign
    redef fun parser_index: Int
    do
	return 64
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPluseq
    redef fun parser_index: Int
    do
	return 65
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TMinuseq
    redef fun parser_index: Int
    do
	return 66
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStareq
    redef fun parser_index: Int
    do
	return 67
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TSlasheq
    redef fun parser_index: Int
    do
	return 68
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPercenteq
    redef fun parser_index: Int
    do
	return 69
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStarstareq
    redef fun parser_index: Int
    do
	return 70
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPipeeq
    redef fun parser_index: Int
    do
	return 71
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TCareteq
    redef fun parser_index: Int
    do
	return 72
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TAmpeq
    redef fun parser_index: Int
    do
	return 73
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TLleq
    redef fun parser_index: Int
    do
	return 74
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TGgeq
    redef fun parser_index: Int
    do
	return 75
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TDotdotdot
    redef fun parser_index: Int
    do
	return 76
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TDotdot
    redef fun parser_index: Int
    do
	return 77
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TDot
    redef fun parser_index: Int
    do
	return 78
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPlus
    redef fun parser_index: Int
    do
	return 79
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TMinus
    redef fun parser_index: Int
    do
	return 80
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStar
    redef fun parser_index: Int
    do
	return 81
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStarstar
    redef fun parser_index: Int
    do
	return 82
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TSlash
    redef fun parser_index: Int
    do
	return 83
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPercent
    redef fun parser_index: Int
    do
	return 84
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TPipe
    redef fun parser_index: Int
    do
	return 85
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TCaret
    redef fun parser_index: Int
    do
	return 86
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TAmp
    redef fun parser_index: Int
    do
	return 87
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TTilde
    redef fun parser_index: Int
    do
	return 88
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TEq
    redef fun parser_index: Int
    do
	return 89
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TNe
    redef fun parser_index: Int
    do
	return 90
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TLt
    redef fun parser_index: Int
    do
	return 91
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TLe
    redef fun parser_index: Int
    do
	return 92
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TLl
    redef fun parser_index: Int
    do
	return 93
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TGt
    redef fun parser_index: Int
    do
	return 94
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TGe
    redef fun parser_index: Int
    do
	return 95
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TGg
    redef fun parser_index: Int
    do
	return 96
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStarship
    redef fun parser_index: Int
    do
	return 97
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TBang
    redef fun parser_index: Int
    do
	return 98
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TQuest
    redef fun parser_index: Int
    do
	return 99
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TAt
    redef fun parser_index: Int
    do
	return 100
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TSemi
    redef fun parser_index: Int
    do
	return 101
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TClassid
    redef fun parser_index: Int
    do
	return 102
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TId
    redef fun parser_index: Int
    do
	return 103
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TAttrid
    redef fun parser_index: Int
    do
	return 104
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TInteger
    redef fun parser_index: Int
    do
	return 105
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TFloat
    redef fun parser_index: Int
    do
	return 106
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TString
    redef fun parser_index: Int
    do
	return 107
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TStartString
    redef fun parser_index: Int
    do
	return 108
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TMidString
    redef fun parser_index: Int
    do
	return 109
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TEndString
    redef fun parser_index: Int
    do
	return 110
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TChar
    redef fun parser_index: Int
    do
	return 111
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TBadString
    redef fun parser_index: Int
    do
	return 112
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TBadTString
    redef fun parser_index: Int
    do
	return 113
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TBadChar
    redef fun parser_index: Int
    do
	return 114
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TExternCodeSegment
    redef fun parser_index: Int
    do
	return 115
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end

redef class TBadExtern
    redef fun parser_index: Int
    do
	return 116
    end

    init init_tk(loc: Location)
    do
		_location = loc
    end
end


redef class EOF
    redef fun parser_index: Int
    do
	return 117
    end
end

redef class Lexer
	redef fun make_token(accept_token, location)
	do
		if accept_token == 1 then
			return new TEol.init_tk(location)
		end
		if accept_token == 2 then
			return new TComment.init_tk(location)
		end
		if accept_token == 3 then
			return new TKwpackage.init_tk(location)
		end
		if accept_token == 4 then
			return new TKwmodule.init_tk(location)
		end
		if accept_token == 5 then
			return new TKwimport.init_tk(location)
		end
		if accept_token == 6 then
			return new TKwclass.init_tk(location)
		end
		if accept_token == 7 then
			return new TKwabstract.init_tk(location)
		end
		if accept_token == 8 then
			return new TKwinterface.init_tk(location)
		end
		if accept_token == 9 then
			return new TKwenum.init_tk(location)
		end
		if accept_token == 10 then
			return new TKwsubset.init_tk(location)
		end
		if accept_token == 11 then
			return new TKwend.init_tk(location)
		end
		if accept_token == 12 then
			return new TKwmeth.init_tk(location)
		end
		if accept_token == 13 then
			return new TKwtype.init_tk(location)
		end
		if accept_token == 14 then
			return new TKwinit.init_tk(location)
		end
		if accept_token == 15 then
			return new TKwredef.init_tk(location)
		end
		if accept_token == 16 then
			return new TKwis.init_tk(location)
		end
		if accept_token == 17 then
			return new TKwdo.init_tk(location)
		end
		if accept_token == 18 then
			return new TKwvar.init_tk(location)
		end
		if accept_token == 19 then
			return new TKwextern.init_tk(location)
		end
		if accept_token == 20 then
			return new TKwpublic.init_tk(location)
		end
		if accept_token == 21 then
			return new TKwprotected.init_tk(location)
		end
		if accept_token == 22 then
			return new TKwprivate.init_tk(location)
		end
		if accept_token == 23 then
			return new TKwintrude.init_tk(location)
		end
		if accept_token == 24 then
			return new TKwif.init_tk(location)
		end
		if accept_token == 25 then
			return new TKwthen.init_tk(location)
		end
		if accept_token == 26 then
			return new TKwelse.init_tk(location)
		end
		if accept_token == 27 then
			return new TKwwhile.init_tk(location)
		end
		if accept_token == 28 then
			return new TKwloop.init_tk(location)
		end
		if accept_token == 29 then
			return new TKwfor.init_tk(location)
		end
		if accept_token == 30 then
			return new TKwin.init_tk(location)
		end
		if accept_token == 31 then
			return new TKwand.init_tk(location)
		end
		if accept_token == 32 then
			return new TKwor.init_tk(location)
		end
		if accept_token == 33 then
			return new TKwnot.init_tk(location)
		end
		if accept_token == 34 then
			return new TKwimplies.init_tk(location)
		end
		if accept_token == 35 then
			return new TKwreturn.init_tk(location)
		end
		if accept_token == 36 then
			return new TKwcontinue.init_tk(location)
		end
		if accept_token == 37 then
			return new TKwbreak.init_tk(location)
		end
		if accept_token == 38 then
			return new TKwabort.init_tk(location)
		end
		if accept_token == 39 then
			return new TKwassert.init_tk(location)
		end
		if accept_token == 40 then
			return new TKwnew.init_tk(location)
		end
		if accept_token == 41 then
			return new TKwisa.init_tk(location)
		end
		if accept_token == 42 then
			return new TKwonce.init_tk(location)
		end
		if accept_token == 43 then
			return new TKwsuper.init_tk(location)
		end
		if accept_token == 44 then
			return new TKwself.init_tk(location)
		end
		if accept_token == 45 then
			return new TKwtrue.init_tk(location)
		end
		if accept_token == 46 then
			return new TKwfalse.init_tk(location)
		end
		if accept_token == 47 then
			return new TKwnull.init_tk(location)
		end
		if accept_token == 48 then
			return new TKwas.init_tk(location)
		end
		if accept_token == 49 then
			return new TKwnullable.init_tk(location)
		end
		if accept_token == 50 then
			return new TKwisset.init_tk(location)
		end
		if accept_token == 51 then
			return new TKwlabel.init_tk(location)
		end
		if accept_token == 52 then
			return new TKwwith.init_tk(location)
		end
		if accept_token == 53 then
			return new TKwdebug.init_tk(location)
		end
		if accept_token == 54 then
			return new TKwyield.init_tk(location)
		end
		if accept_token == 55 then
			return new TKwcatch.init_tk(location)
		end
		if accept_token == 56 then
			return new TOpar.init_tk(location)
		end
		if accept_token == 57 then
			return new TCpar.init_tk(location)
		end
		if accept_token == 58 then
			return new TObra.init_tk(location)
		end
		if accept_token == 59 then
			return new TCbra.init_tk(location)
		end
		if accept_token == 60 then
			return new TObrace.init_tk(location)
		end
		if accept_token == 61 then
			return new TCbrace.init_tk(location)
		end
		if accept_token == 62 then
			return new TComma.init_tk(location)
		end
		if accept_token == 63 then
			return new TColumn.init_tk(location)
		end
		if accept_token == 64 then
			return new TQuad.init_tk(location)
		end
		if accept_token == 65 then
			return new TAssign.init_tk(location)
		end
		if accept_token == 66 then
			return new TPluseq.init_tk(location)
		end
		if accept_token == 67 then
			return new TMinuseq.init_tk(location)
		end
		if accept_token == 68 then
			return new TStareq.init_tk(location)
		end
		if accept_token == 69 then
			return new TSlasheq.init_tk(location)
		end
		if accept_token == 70 then
			return new TPercenteq.init_tk(location)
		end
		if accept_token == 71 then
			return new TStarstareq.init_tk(location)
		end
		if accept_token == 72 then
			return new TPipeeq.init_tk(location)
		end
		if accept_token == 73 then
			return new TCareteq.init_tk(location)
		end
		if accept_token == 74 then
			return new TAmpeq.init_tk(location)
		end
		if accept_token == 75 then
			return new TLleq.init_tk(location)
		end
		if accept_token == 76 then
			return new TGgeq.init_tk(location)
		end
		if accept_token == 77 then
			return new TDotdotdot.init_tk(location)
		end
		if accept_token == 78 then
			return new TDotdot.init_tk(location)
		end
		if accept_token == 79 then
			return new TDot.init_tk(location)
		end
		if accept_token == 80 then
			return new TPlus.init_tk(location)
		end
		if accept_token == 81 then
			return new TMinus.init_tk(location)
		end
		if accept_token == 82 then
			return new TStar.init_tk(location)
		end
		if accept_token == 83 then
			return new TStarstar.init_tk(location)
		end
		if accept_token == 84 then
			return new TSlash.init_tk(location)
		end
		if accept_token == 85 then
			return new TPercent.init_tk(location)
		end
		if accept_token == 86 then
			return new TPipe.init_tk(location)
		end
		if accept_token == 87 then
			return new TCaret.init_tk(location)
		end
		if accept_token == 88 then
			return new TAmp.init_tk(location)
		end
		if accept_token == 89 then
			return new TTilde.init_tk(location)
		end
		if accept_token == 90 then
			return new TEq.init_tk(location)
		end
		if accept_token == 91 then
			return new TNe.init_tk(location)
		end
		if accept_token == 92 then
			return new TLt.init_tk(location)
		end
		if accept_token == 93 then
			return new TLe.init_tk(location)
		end
		if accept_token == 94 then
			return new TLl.init_tk(location)
		end
		if accept_token == 95 then
			return new TGt.init_tk(location)
		end
		if accept_token == 96 then
			return new TGe.init_tk(location)
		end
		if accept_token == 97 then
			return new TGg.init_tk(location)
		end
		if accept_token == 98 then
			return new TStarship.init_tk(location)
		end
		if accept_token == 99 then
			return new TBang.init_tk(location)
		end
		if accept_token == 100 then
			return new TQuest.init_tk(location)
		end
		if accept_token == 101 then
			return new TAt.init_tk(location)
		end
		if accept_token == 102 then
			return new TSemi.init_tk(location)
		end
		if accept_token == 103 then
			return new TClassid.init_tk(location)
		end
		if accept_token == 104 then
			return new TId.init_tk(location)
		end
		if accept_token == 105 then
			return new TAttrid.init_tk(location)
		end
		if accept_token == 106 then
			return new TInteger.init_tk(location)
		end
		if accept_token == 107 then
			return new TFloat.init_tk(location)
		end
		if accept_token == 108 then
			return new TString.init_tk(location)
		end
		if accept_token == 109 then
			return new TStartString.init_tk(location)
		end
		if accept_token == 110 then
			return new TMidString.init_tk(location)
		end
		if accept_token == 111 then
			return new TEndString.init_tk(location)
		end
		if accept_token == 112 then
			return new TChar.init_tk(location)
		end
		if accept_token == 113 then
			return new TBadString.init_tk(location)
		end
		if accept_token == 114 then
			return new TBadTString.init_tk(location)
		end
		if accept_token == 115 then
			return new TBadChar.init_tk(location)
		end
		if accept_token == 116 then
			return new TExternCodeSegment.init_tk(location)
		end
		if accept_token == 117 then
			return new TBadExtern.init_tk(location)
		end
		abort # unknown token index `accept_token`
	end
end

