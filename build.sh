#!/bin/bash

rm -rf build
mkdir -p build

# Set the BEEBASM executable for the platform
# Let's see if the user already has one on their path
BEEBASM=$(type -path beebasm 2>/dev/null)
if [ "$(uname -s)" == "Darwin" ]; then
    BEEBASM=${BEEBASM:-tools/beebasm/beebasm-darwin}
    MD5SUM=md5
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    if [ "$(uname -m)" == "x86_64" ]; then
        BEEBASM=${BEEBASM:-tools/beebasm/beebasm64}
    else
        BEEBASM=${BEEBASM:-tools/beebasm/beebasm32}
    fi
    MD5SUM=md5sum
elif [ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]; then
    BEEBASM=${BEEBASM:-tools/beebasm/beebasm.exe}
    MD5SUM=md5sum
fi
echo Using $BEEBASM

ssd=adfs.ssd

# Create a blank SSD image
tools/mmb_utils/blank_ssd.pl build/${ssd}
echo

cd src
for top in `ls top_*.asm`
do
    name=`echo ${top%.asm} | cut -c5-`
    echo "Building $name..."

    # Assember the ROM
    $BEEBASM -i ${top} -o ../build/${name} -v >& ../build/${name}.log

    # Check if ROM has been build, otherwise fail early
    if [ ! -f ../build/${name} ]
    then
        cat ../build/${name}.log
        echo "build failed to create ${name}"
        exit
    fi

    # Create the .inf file
    echo -e "\$."${name}"\t8000\t8000" > ../build/${name}.inf

    # Add into the SSD
    ../tools/mmb_utils/putfile.pl ../build/${ssd} ../build/${name}

    # Report end of code
    grep "code ends at" ../build/${name}.log

    # Report build checksum
    echo "    mdsum is "`$MD5SUM <../build/${name}`
done
cd ..

echo
tools/mmb_utils/info.pl  build/${ssd}
