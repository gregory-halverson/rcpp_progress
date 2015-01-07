R=R
VERSION=0.2
RDEVEL=rocker/r-devel
RCHECKER=rcpp-rdevel
NCPUS=4

clean:
	rm -f  src/*.o src/*.so */*~ *~ src/*.rds manual.pdf
	rm -rf *.Rcheck/ checks .Rd2pdf*
	rm -f RcppProgress_$(VERSION).tar.gz
	$(shell bash -c "shopt -s globstar && rm -f **/*.o **/*.so")

install: RcppProgress_$(VERSION).tar.gz
	$(R) CMD INSTALL $<

test-RcppProgressArmadillo: install
	R CMD INSTALL inst/examples/RcppProgressArmadillo/
	Rscript test_rcpp_armadillo_example.R

test-RcppProgressExample: install
	R CMD INSTALL inst/examples/RcppProgressExample/
	Rscript test_rcpp_example.R

tests: test-RcppProgressExample test-RcppProgressArmadillo

RcppProgress_$(VERSION).tar.gz: 
	$(R) CMD build .

check: clean
	$(R) CMD build .
	$(R) CMD check RcppProgress_$(VERSION).tar.gz

doc:
	$(R) CMD Rd2pdf -o manual.pdf .

build-docker-checker:
	docker build -t $(RCHECKER) docker_checker

RDEVEL=rocker/r-devel
RCHECKER=rcpp-rdevel

#build_rchecker:
#	docker pull $(RDEVEL)
#	docker run --name $(RCHECKER) -ti -v $(PWD):/tmp/ -w /tmp -u docker $(RDEVEL) Rscript -e 'install.packages("Rcpp")'

check-r-devel: RcppProgress_$(VERSION).tar.gz build-docker-checker
	-docker rm  $(RCHECKER)
	docker run --name $(RCHECKER) -ti -v $(PWD):/tmp/ -w /tmp -u docker $(RCHECKER) R CMD check --as-cran RcppProgress_$(VERSION).tar.gz


win-builder-upload: RcppProgress_$(VERSION).tar.gz
	lftp  -u anonymous,karl.forner@gmail.com -e "set ftp:passive-mode true; cd R-release; put RcppProgress_$(VERSION).tar.gz; cd ../R-devel;  put RcppProgress_$(VERSION).tar.gz; bye" ftp://win-builder.r-project.org

run-r-devel: RcppProgress_$(VERSION).tar.gz build-docker-checker
	-docker rm  $(RCHECKER)
	docker run --name $(RCHECKER) -ti -v $(PWD):/tmp/ -w /tmp -u docker $(RCHECKER) bash

#fetch-dependent-packages:
#	Rscript -e 'pkgs <- available.packages(); deps <- tools::package_dependencies("RcppProgress", pkgs, which = "all", reverse = TRUE)[[1]];download.packages(deps, ".")'


check-rdevel-deps: RcppProgress_$(VERSION).tar.gz build-docker-checker 
	-docker rm  $(RCHECKER)
	-mkdir checks
	cp RcppProgress_$(VERSION).tar.gz checks
	docker run --rm --name $(RCHECKER) -ti -v $(PWD):/tmp/ -w /tmp -u docker $(RCHECKER) Rscript -e 'setwd("checks");library(tools);check_packages_in_dir(".", reverse=TRUE, Ncpus=$(NCPUS));summarize_check_packages_in_dir_results(".")'
