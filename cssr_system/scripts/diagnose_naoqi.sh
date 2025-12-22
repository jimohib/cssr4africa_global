#!/bin/bash
# Diagnostic script to check NAOqi Python 2 installation

echo "=== NAOqi SDK Diagnostic ==="
echo

echo "1. Checking Python 2 installation:"
which python2
python2 --version
echo

echo "2. Checking if naoqi module is accessible:"
python2 -c "import sys; print('Python path:'); [print('  -', p) for p in sys.path]"
echo

echo "3. Attempting to import naoqi:"
python2 -c "from naoqi import ALProxy; print('✓ naoqi module imported successfully')" 2>&1
echo

echo "4. Attempting to import qi:"
python2 -c "import qi; print('✓ qi module imported successfully')" 2>&1
echo

echo "5. Checking PYTHONPATH environment variable:"
echo "PYTHONPATH=${PYTHONPATH:-<not set>}"
echo

echo "6. Checking for naoqi in common locations:"
for dir in /usr/local/lib/python2.7/dist-packages /usr/lib/python2.7/dist-packages ~/.local/lib/python2.7/site-packages /opt/aldebaran/lib/python2.7/site-packages; do
    if [ -d "$dir" ]; then
        echo "  Checking: $dir"
        find "$dir" -name "*naoqi*" -o -name "*qi*" 2>/dev/null | head -5
    fi
done
echo

echo "=== End Diagnostic ==="
