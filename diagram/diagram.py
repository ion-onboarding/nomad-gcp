
   
# https://diagrams.mingrammer.com/docs/nodes/aws

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.network import Consul
from diagrams.onprem.compute import Nomad
from diagrams.aws.compute import ApplicationAutoScaling

outformat="png"
filename_nomad="diagram"

graph_attr = {
    "layout":"dot",
    "compound":"true",
    "splines":"spline",
    }

with Diagram("1Regions 1Datacenters\n", filename=filename_nomad, direction="TB",outformat=outformat, graph_attr=graph_attr):
    with Cluster("CLOUD gcp"):
        with Cluster("REGION emea"):
            with Cluster("SERVERS emea"):
                consul1_emea = Consul("consul")
                nomad1_emea = Nomad("nomad")
            #     consul1_emea - consul2_emea - consul3_emea
            #     nomad1_emea - nomad2_emea - nomad3_emea
            with Cluster("DATACENTER amsterdam"):
                client1_amsterdam = Nomad("client")
            #     client2_amsterdam = Nomad("client")
            #     client3_amsterdam = Nomad("client")
            #     client1_amsterdam - client2_amsterdam - client3_amsterdam
            [consul1_emea] - Edge(penwidth = "4", lhead = "cluster_DATACENTER amsterdam", ltail="cluster_SERVERS emea") - client1_amsterdam
            [nomad1_emea] - Edge(penwidth = "4", lhead = "cluster_DATACENTER amsterdam", ltail="cluster_SERVERS emea") - client1_amsterdam