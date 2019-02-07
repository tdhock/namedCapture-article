HOCKING-namedCapture.pdf: HOCKING-namedCapture.tex HOCKING-RJtemplate.tex RJreferences.bib
	rm -f *.aux *.bbl
	pdflatex HOCKING-namedCapture
	bibtex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
