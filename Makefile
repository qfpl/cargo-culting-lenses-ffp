HIGHSTYLE := espresso
CSS := css/custom.css

talk.html: presentation.md
	pandoc -t revealjs -s $< --highlight-style=$(HIGHSTYLE) --css=$(CSS) -o $@

talk.tex: presentation.md
	pandoc -t beamer -s $< --highlight-style=$(HIGHSTYLE) --css=$(CSS) -o $@

all: talk.html
