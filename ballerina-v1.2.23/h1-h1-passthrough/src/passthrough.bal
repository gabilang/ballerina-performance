import ballerina/http;
import ballerina/log;
import ballerina/docker;
 
@docker:Expose {}
listener http:Listener securedEP = new(9090, {
    secureSocket: {
        keyStore: {
            path: "security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
});

http:Client nettyEP = new("https://netty:8688", {
    secureSocket: {
        trustStore: {
            path: "security/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostname: false
    }
});

@docker:Config {push: true,
   registry: "index.docker.io/$env{DOCKER_USERNAME}",
   name: "v1_passthrough",
   tag: "latest",
   username: "$env{DOCKER_USERNAME}",
   password: "$env{DOCKER_PASSWORD}"
}

@http:ServiceConfig { basePath: "/passthrough" }
service passthrough on securedEP {
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }
    resource function passthrough(http:Caller caller, http:Request clientRequest) {
        var response = nettyEP->forward("/service/EchoService", clientRequest);
        if (response is http:Response) {
            var result = caller->respond(response);
        } else {
            log:printError("Error at h1_h1_passthrough", <error>response);
                        http:Response res = new;
            res.statusCode = 500;
            res.setPayload(response.detail()?.message);
            var result = caller->respond(res);
        }
    }
}
