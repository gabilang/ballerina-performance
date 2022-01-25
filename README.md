# ballerina-performance
### Summary of performance test results
The following is the summary of performance test results collected for the h1-h1-passthrough scenario.  
Number of concurrent users: 100  
Protocol: https  
Duration: 1800s    

| Version | Message Size (Bytes) | Average Response Time (ms) | Standard Deviation of Response Time (ms) | Error % | Throughput (Requests/sec) | Throughput (KB/s) |
| --- | --- | --- | --- | --- | --- | --- |
| 2201.0.0 | 1024 | 43.28 | 43.33 | 0.00% | 2249.23 | 2532.6 | 
| slbeta3 | 1024 | 43.24 | 43.25 | 0.00% | 2239.13 | 2521.19 |
| slalpha5 | 1024 |
| v1.2.23 | 1024 | 56.38 | 56.78 | 0.00% | 1730.9 | 1948.93 |


### Setting Up the performance test environment in local machine
#### Prerequisites
1. Download and install docker, minikube and Kubernetes.
    - [Docker](https://docs.docker.com/engine/install/)
    - [Minikube](https://kubernetes.io/docs/tasks/tools/#minikube)
    - [K8s](https://kubernetes.io/releases/download/)
2. Start a K8s cluster locally with Minikube
    ```
    $ minikube start
    ```
#### Deploy netty backend to K8s (use the YAML file provided in ballerina-performance/deployment-netty-backend).
    $ kubectl apply -f ./deployment-netty-backend/netty-backend.yaml
    
#### Building the source with specific version and deploy it to K8s.
1. To build test scenario source
    ```
    $ bal build
    ```
    (eg. to build the h1-h1-passthrough program with beta3, navigate to the ./ballerina-slbeta3/h1-h1-passthrough/src and execute `$ bal build` command)
2. To build and push the docker image
    ```
    $ docker build -t <DOCKER_USERNAME>/passthrough_beta3:latest target/docker/passthrough_beta3
    $ docker push <DOCKER_USERNAME>/passthrough_beta3:latest
    ```
3. To deploy the https passthrough service to K8s
    ```
    $ kubectl apply -f ./target/kubernetes/passthrough_beta3  
    $ kubectl expose deployment passthrough-bet-deployment --type=NodePort --name=passthrough-bet-svc-local  
    ```
4. To test the backend echo service
    ```
    $ curl -kv https://localhost:8688/service/EchoService -d '{"size":"50B","payload":"0123456789ABCDEFGHIJKLM"}'
    ```
5. To test the passthrough service
    ```
    $ curl -kv -X POST https://192.168.49.2:<NodePort>/passthrough -d '{"size":"50B","payload":"0123456789ABCDEFGHIJKLM"}'
    ```
6. To run the load test using JMeter
    ```
    $ jmeter -n -t ./resources/jmeter/http-post-request.jmx -l results.jtl -Jusers=100 -Jduration=1800 -JrampUpPeriod=300 -Jhost=192.168.49.2 -Jport=<NodePort> -Jprotocol=https -Jpath=passthrough -Jpayload="./resources/payload/1024B.json" -Jresponse_size=1024
    ```


