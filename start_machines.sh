# CONSUL
  # Create machine
    docker-machine create -d virtualbox consul
  # export the consul as a ENV Variable
    export KV_IP=$(docker-machine ssh consul 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
  # enters the machine
    eval $(docker-machine env consul)
  # setup the container
    docker run -d -p ${KV_IP}:8500:8500 -h consul --restart always gliderlabs/consul-server -bootstrap

# SWARM
    # master
      # create machine
        docker-machine create -d virtualbox --swarm --swarm-master --swarm-discovery="consul://${KV_IP}:8500" --engine-opt="cluster-store=consul://${KV_IP}:8500" --engine-opt="cluster-advertise=eth1:2376" master
      # export IP
        export MASTER_IP=$(docker-machine ssh master 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
    # slave
      # create machine
        docker-machine create -d virtualbox --swarm --swarm-discovery="consul://${KV_IP}:8500" --engine-opt="cluster-store=consul://${KV_IP}:8500" --engine-opt="cluster-advertise=eth1:2376" slave
      # export ip
        export SLAVE_IP=$(docker-machine ssh slave 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')

    # registrator
      # enters swarm master machine
        eval $(docker-machine env master)

        # setup
          docker run -d --name=registrator -h ${MASTER_IP} --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://${KV_IP}:8500

      # enters the slave machine
        eval $(docker-machine env slave)

        #setup
          docker run -d --name=registrator -h ${SLAVE_IP} --volume=/var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator:latest consul://${KV_IP}:8500
