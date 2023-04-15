
cat ./sound.wav | socat unix-sendto:/tmp/fm.sock -

socat unix-recvfrom:/tmp/fm.sock,fork,mode=777 stdout | mbuffer |  sudo /home/gohiki/workspace/radio/pifm -
