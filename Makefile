HOCKING-namedCapture.pdf: HOCKING-namedCapture.Rnw RJreferences.bib
	rm -f *.aux *.bbl
	R CMD Sweave HOCKING-namedCapture.Rnw
	pdflatex HOCKING-namedCapture
	bibtex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	rm HOCKING-namedCapture.tex
