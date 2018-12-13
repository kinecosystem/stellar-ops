#! /bin/sh

echo "-------------------------"
echo "erasing core db..."
echo "-------------------------"
docker-compose run --rm stellar-core --newdb
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo "failed to erase db. bailing."
    exit $exit_status
fi

echo "-------------------------"
echo "erasing history bucket..."
echo "-------------------------"
docker-compose run --rm stellar-core --newhist my-bucket
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo "failed to erase bucket. bailing."
    exit $exit_status
fi

echo "-----------------------------------------------"
read -r -p "Are you sure you want to start the core? [y/N] " response
echo "-----------------------------------------------"
case "$response" in
    [yY][eE][sS]|[yY])
    echo "----------------"
    echo "starting core..." 
    echo "----------------"
	docker-compose up -d

	exit_status=$?
	if [ $exit_status -ne 0 ]; then
	    echo "failed to start core. bailing."
	    exit $exit_status
	else
		echo "docker ps output:"
		docker ps
	fi
        ;;
    *)
        echo "ok. bye now!"
        exit
        ;;
esac

