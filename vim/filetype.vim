if exists("did_load_filetypes")
  finish
endif

augroup filetypedetect
  " AVRO
  au BufNewFile,BufRead *.avsc setf json
augroup END
