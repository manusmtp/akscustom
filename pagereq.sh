echo "Enter URL"
read URL
for i in $(seq 1 50)
do
	curl /dev/null -s -o $URL
	
	curl /dev/ -s -o $URL

done
