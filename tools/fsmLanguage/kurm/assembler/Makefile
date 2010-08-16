all: Main tidy

Main:
	ghc --make Main.hs
	mv Main assemble

tidy:
	$(RM) *.hi *.o

clean: tidy
	$(RM) assemble

.PHONY: Main clean
