#!/bin/sh

############### General Information ############################################
# Introduction:
# This shell script was written by Swaroop C H <swaroop@byteofpython.info>
# It was written *only* for personal purpose. So, YMMV (Your Mileage May Vary).
# This script is in the public domain. Use it for any purpose you want.
# See www.sagehill.net/docbookxsl/InstallingAProcessor.html for details

# TODO:
# 1. Bring back XHTML validation in bytecolorizer.py
# 2. Use <?dbhtml?> for chunking to directories:
#    - www.sagehill.net/docbookxsl/Chunking.html - see "dbhtml processing instruction"
#    - note that directories *have to exist before* the transformation

############### Initialization #################################################
# Create output directory
mkdir -p output

# Type of output
type="$1"
if [ -z $type ]
then
	type="xhtml"
fi

# version information
if [ ! -f 'VERSION' ]
then
	echo "VERSION file missing"
	exit 2
fi
version=`head -1 VERSION`

############### Validation #####################################################
if [ $type = "validate" ]
then
	echo "Validation"

	xmllint --noout --nonet --postvalid --dtdvalid \
	  docbook-dtd/docbookx.dtd \
	  index.xml
	if [ $? -eq 0 ]
	then
		echo "Success"
	fi

############### XHTML ##########################################################
elif [ $type = "xhtml-single" ]
then
	echo "XHTML single"

	dst="output/byteofpython_html_single"
	rm -rf $dst
	mkdir $dst

	xsltproc \
		--output $dst/byteofpython_$version.html \
	         --stringparam use.extensions '0' \
	         --stringparam html.stylesheet 'byte.css' \
	         --stringparam use.id.as.filename '1' \
	         --stringparam chunker.output.encoding 'UTF-8' \
	         --stringparam navig.graphics '1' \
	         docbook-xsl/xhtml/docbook.xsl \
	         index.xml
	         # --stringparam navig.graphics.extension '.png' \
	         # --stringparam admon.graphics '1' \
	         # --stringparam section.autolabel '1' \
	         # --stringparam section.label.includes.component.label '1' \
	         # --stringparam saxon.character.representation 'native;decimal' \

	cp byte.css $dst
	cp -r docbook-xsl/images $dst

	# Colorizer
	python bytecolorizer.py $dst/byteofpython_$version.html

############### Chunked XHTML ##################################################
elif [ $type = "xhtml" ]
then
	echo "XHTML in chunks"

	dst="output/byteofpython_html"
	rm -rf $dst
	mkdir $dst

	xsltproc \
	         --stringparam use.extensions '0' \
	         --stringparam html.stylesheet 'byte.css' \
	         --stringparam use.id.as.filename '1' \
	         --stringparam base.dir "$dst/" \
	         --stringparam chunker.output.encoding 'UTF-8' \
	         --stringparam navig.graphics '1' \
	         docbook-xsl/xhtml/chunk.xsl \
	         index.xml
	         # --stringparam navig.graphics.extension '.png' \
	         # --stringparam admon.graphics '1' \
	         # --stringparam section.autolabel '1' \
	         # --stringparam section.label.includes.component.label '1' \
	         # --stringparam saxon.character.representation 'native;decimal' \

	cp byte.css $dst
	cp -r docbook-xsl/images $dst

	# Colorizer
	for html in $dst/*.html
	do
		python bytecolorizer.py $html
	done

############### FO #############################################################
elif [ $type = "fo" ]
then
	echo "FO"

	dst="output"
	rm $dst/byteofpython_$version.fo

	xsltproc \
	         --output "$dst/byteofpython_$version.fo"
	         docbook-xsl/fo/docbook.xsl \
	         index.xml
	
############### TXT ############################################################
elif [ $type = "txt" ]
then
	echo "TXT"

	dst="output"
	rm -f $dst/byteofpython_$version.txt

	xmlto \
	      -o "$dst/" \
	      txt \
	      index.xml
	
	mv $dst/index.txt $dst/byteofpython_$version.txt
	 
############### PDF ############################################################
elif [ $type = "pdf" ]
then
	echo "PDF"

	dst="output"
	rm -f $dst/byteofpython_$version.pdf

	# Using the 'convenience' scripts:
	export JAVACMD=`which java`
	sh fop/fop.sh \
	   -xml index.xml \
	   -xsl docbook-xsl/fo/docbook.xsl \
	   -pdf $dst/byteofpython_$version.pdf

############### Dist ###########################################################
elif [ $type = "dist" ]
then
	echo "DIST"

	# Check XHTML single
	if [ -d "output/byteofpython_html_single" ]
	then
		echo "XHTML single is present"
	else
		echo "XHTML single is NOT present"
		echo "Run this first: ./make.sh xhtml-single"
		exit 3
	fi
	# Check XHTML
	if [ -d "output/byteofpython_html" ]
	then
		echo "XHTML is present"
	else
		echo "XHTML is NOT present"
		echo "Run this first: ./make.sh xhtml"
		exit 3
	fi
	# Check TXT
	if [ -f "output/byteofpython_$version.txt" ]
	then
		echo "TXT is present"
	else
		echo "TXT is NOT present"
		echo "Run this first: ./make.sh txt"
		exit 3
	fi
	# Check PDF
	if [ -f "output/byteofpython_$version.pdf" ]
	then
		echo "PDF is present"
	else
		echo "PDF is NOT present"
		echo "Run this first: ./make.sh pdf"
		exit 3
	fi

	echo "Proceeding to creating archives"

	# Change to output directory
	cd output

	# Zip XHTML
	rm -f byteofpython_html_single_$version.zip
	zip -qr byteofpython_html_single_$version.zip byteofpython_html_single
	echo "Created XHTML single archive"

	# Zip XHTML single
	rm -f byteofpython_html_$version.zip
	zip -qr byteofpython_html_$version.zip byteofpython_html
	echo "Created XHTML archive"

	# Switch back to main directory
	cd ..

	# Create source tarball
	rm -f output/byteofpython_source_$version.tar.gz
	tar -czf output/byteofpython_source_$version.tar.gz *.xml *.py *.sh *.css code VERSION
	echo "Created source archive"

	# Create fullsource tarball
	maindir=`pwd`
	cd ..
	rm -f byteofpython_fullsource_$version.tar.gz
	tar -czf byteofpython_fullsource_$version.tar.gz `basename $maindir`
	echo "Created fullsource archive"
	cd $maindir

############### Else Error #####################################################
else
	echo "Error: Invalid format '$type' specified"
	exit 1
fi

echo "Done"

# The End
# vim: set smartindent
