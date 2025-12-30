#!/usr/bin/env python3
# wifi_topo.py
from mininet.node import RemoteController, OVSSwitch
from mn_wifi.net import Mininet_wifi
from mn_wifi.node import Station, AccessPoint
from mn_wifi.cli import CLI
from mn_wifi.link import wmediumd, mesh
from mn_wifi.wmediumdConnector import interference

def topology():
    net = Mininet_wifi(controller=RemoteController, switch=OVSSwitch, link=wmediumd, wmediumd_mode=interference)

    print("*** Creating nodes")
    sta1 = net.addStation('sta1', ip='10.0.0.1/8')
    sta2 = net.addStation('sta2', ip='10.0.0.2/8')
    ap1 = net.addAccessPoint('ap1', ssid='ssid-ap1', mode='g', channel='1', position='50,50,0')
    c1 = net.addController('c1', controller=RemoteController, ip='172.19.0.3', port=6633)  # docker bridge IP of ryu service

    net.configureWifiNodes()
    net.addLink(sta1, ap1)
    net.addLink(sta2, ap1)

    print("*** Starting network")
    net.build()
    c1.start()
    ap1.start([])

    print("*** Running tests")
    net.pingAll()
    CLI(net)
    net.stop()

if __name__ == '__main__':
    topology()