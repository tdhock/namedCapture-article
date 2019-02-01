HOCKING-namedCapture.pdf: HOCKING-namedCapture.tex HOCKING-RJtemplate.tex
	pdflatex HOCKING-namedCapture
	bibtex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
	pdflatex HOCKING-namedCapture
