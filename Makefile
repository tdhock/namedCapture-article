submission.zip: RJwrapper.pdf
	mkdir -p submission
	cp figure-timings-*.R figure-timings-*.pdf figure-timings-*.png hocking.bib hocking.R hocking-edited.tex letter-to-editor.pdf log.R log.rds Makefile pathological-backref.R pathological-backref.rds pathological.R pathological.rds RJwrapper.pdf RJwrapper.tex sacct.R sacct.rds trackDb.R trackDb.rds submission
	zip submission submission/* 
RJwrapper.pdf: hocking-edited.tex hocking.bib figure-timings-first-linetype.png figure-timings-all-linetype.png figure-timings-pathological-linetype.png
	R -e 'tools::texi2pdf("RJwrapper.tex")'
hocking-edited.Rnw: hocking-remove-space.R hocking.Rnw 
	R --vanilla < $<
hocking-edited.tex: hocking-edited.Rnw
	R CMD Stangle $<
	#R -e 'knitr::knit("hocking-edited.Rnw")'
	R CMD Sweave $<
HOCKING-namedCapture.pdf: HOCKING-namedCapture.Rnw RJreferences.bib pathological.rds log.rds trackDb.rds sacct.rds figure-timings-first.pdf figure-timings-all.pdf figure-timings-pathological.pdf
	rm -f *.aux *.bbl
	R CMD Sweave HOCKING-namedCapture.Rnw
	pdflatex HOCKING-namedCapture
	bibtex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	rm HOCKING-namedCapture.tex
figure-timings-first-linetype.png: figure-timings-first.R sacct.rds log.rds
	R --vanilla < $<
figure-timings-all-linetype.png: figure-timings-all.R trackDb-3.5.2.rds trackDb-3.6.0.rds
	R --vanilla < $<
figure-timings-pathological-linetype.png: figure-timings-pathological.R pathological.rds pathological-backref.rds
	R --vanilla < $<
pathological.rds: pathological.R
	R --vanilla < $<
pathological-backref.rds: pathological-backref.R
	R --vanilla < $<
log.rds: log.R
	R --vanilla < $<
trackDb-3.6.0.rds: trackDb.R
	~/bin/R-3.6.0 --vanilla --args trackDb-3.6.0.rds < $<
trackDb-3.5.2.rds: trackDb.R
	~/bin/R-3.5.2 --vanilla --args trackDb-3.5.2.rds < $<
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
