if exists("b:current_syntax")
  finish
endif

let b:current_syntax = "jack"

syn keyword jackClass class nextgroup=jackClassName skipwhite
syn region jackClassDeclaration start='class' end='{' contains=jackClassName
syn match jackClassName '[_A-Z]\+[a-z0-9_]*' contained

syn keyword jackSubroutine constructor method function nextgroup=jackType skipwhite

syn keyword jackKeyword do while return if var let
syn keyword jackType void int char boolean String Array
syn keyword jackBoolean true false

syn match jackNumber '\d\+'
syn region jackString start='"' end='"'

syn match jackComment "//.*$"

hi def link jackClass Statement
hi def link jackKeyword Statement
hi def link jackClassName Identifier
hi def link jackSubroutine Statement
hi def link jackType Type
hi def link jackBoolean Boolean
hi def link jackNumber Number
hi def link jackString String
hi def link jackComment Comment
