#i!/bin/bash
kill -9  `pgrep -f dsiprouter`
if [ $? -eq 0 ]; then

	echo "dSIPRouter is stopped"
fi
