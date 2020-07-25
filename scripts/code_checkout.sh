if ! ls /opt | grep -qF "code"; then
	mkdir /opt/code
    	echo "Creating New Code Diretcory"
else
	rm -rf /opt/code/*
	echo "Code directoty already present"
fi
cp -ap $WORKSPACE/. /opt/code/ 

