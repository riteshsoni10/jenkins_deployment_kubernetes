if ! ls /opt | grep -qF "code"; then
	mkdir /opt/code
    echo "Creating New Code Diretcory"
else
	echo "Code directoty already present"
fi
cp -ap $WORKSPACE/* /opt/code/ 

