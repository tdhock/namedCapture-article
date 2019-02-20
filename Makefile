HOCKING-namedCapture.pdf: HOCKING-namedCapture.Rnw RJreferences.bib pathological.rds log.rds trackDb.rds sacct.rds
	rm -f *.aux *.bbl
	R CMD Sweave HOCKING-namedCapture.Rnw
	pdflatex HOCKING-namedCapture
	bibtex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	rm HOCKING-namedCapture.tex
pathological.rds: pathological.R
	R --vanilla < $<
log.rds: log.R
	R --vanilla < $<
trackDb.rds: trackDb.R
	~/R/R-3.5.1/bin/R --vanilla < $<
sacct.rds: sacct.R
	R --vanilla < $<
pcre2demo.out: pcre2demo
	./pcre2demo -g trackDb-31622.txt
pcre2demo: pcre2demo.c
	gcc -g -Wall $< -lpcre2-8 -o pcre2demo
pcre_demo.out: pcre_demo
	./pcre_demo -g trackDb-31622.txt
pcre_demo: pcre_demo.c
	gcc -Wall $< -lpcre -o pcre_demo
