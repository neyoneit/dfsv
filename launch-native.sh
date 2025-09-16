#!/bin/bash
source sv.conf
COUNTER=0
echo "Checking sv.conf for required settings..."
for CONFIGURABLE in SV_BASE_HOSTNAME SV_RCON SV_LOCATION ADMIN_NAME; do
	if [[ "${!CONFIGURABLE}" = "" ]]
	then
		read -p "Enter $CONFIGURABLE: " $CONFIGURABLE
	fi
done
printf "\nServer Hostname: $SV_BASE_HOSTNAME\nAdmin: $ADMIN_NAME\nRcon Password: $SV_RCON\nServer Location: $SV_LOCATION\n\n"

echo "Setting up native server environment..."

# Mount NFS maps if not already mounted
if ! mountpoint -q ./nfs/maps; then
    echo "Mounting NFS maps directory..."
    sudo mkdir -p ./nfs/maps
    sudo mount -t nfs -o nolock,soft,timeo=30 173.212.241.188:/maps/bsp ./nfs/maps
    if [ $? -eq 0 ]; then
        echo "NFS maps mounted successfully"
    else
        echo "Warning: Failed to mount NFS maps. Maps may not be available."
    fi
fi

curr_port=27960
echo "Starting servers natively..."

for sv_type in mixed cpm vq3 fastcaps teamruns freestyle;do
	i=0
	sv_qty="${sv_type}_count"
	sv_sfx="${sv_type}_sfx"
	while [[ $i -ne "${!sv_qty}" ]]
	do
		curr_id="rs${curr_port}"
		i=$(($i+1))
		curr_name="${sv_type}_${i}"
		curr_hostname="${SV_BASE_HOSTNAME} ${!sv_sfx} ${i}"

		echo "Starting server: $curr_name on port $curr_port"

		# Create server-specific directory
		sudo mkdir -p servers/base/defrag/$curr_name
		sudo cp cfgs/${sv_type}.cfg servers/base/defrag/$curr_name/main.cfg

		# Start the server in background
		cd servers/base
		export MDD_ENABLED=${MDD_ENABLED}
		export RS_ID=${!curr_id}
		export NAME_ID=${curr_name}
		export SV_TYPE=${sv_type}
		export SV_HOSTNAME="${curr_hostname}"
		export SV_RCON=${SV_RCON}
		export SV_LOCATION=${SV_LOCATION}
		export SV_PORT=${curr_port}
		export ADMIN_NAME=${ADMIN_NAME}
		export ADMIN_MAIL=${ADMIN_MAIL}
		export ADMIN_DISCORD=${ADMIN_DISCORD}
		export ADMIN_IRC=${ADMIN_IRC}
		export SV_MAPBASE=${SV_MAPBASE}
		export SV_HOMEPAGE=${SV_HOMEPAGE}
		export SV_PRIVATE=${SV_PRIVATE}
		export SV_PASSWORD=${SV_PASSWORD}

		# Start server using existing start.sh script
		nohup ./start.sh > logs/${curr_name}.log 2>&1 &
		SERVER_PID=$!
		echo "Server $curr_name started with PID $SERVER_PID"
		echo $SERVER_PID > logs/${curr_name}.pid

		cd ../..
		curr_port=$(($curr_port+1))
	done
done

echo "All servers started! Check server connections with /connect $(hostname -I | cut -d' ' -f1) through a defrag client"
echo "Server logs are available in servers/base/logs/"