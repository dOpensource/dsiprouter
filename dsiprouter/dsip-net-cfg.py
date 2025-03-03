#!/usr/bin/env python3
#
# Handle any network configurations that need setup prior to the dSIPRouter services starting
# Usage: ./dsip-net-cfg.py [cloud platform] [network mode]
#

# make sure the generated source files are imported instead of the template ones
import sys
if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import requests, subprocess, json
import settings

# get variables either from CLI args or settings file
args = sys.argv[1:]
try:
    cloud_platform = args[0]
except IndexError:
    cloud_platform = settings.CLOUD_PLATFORM
try:
    network_mode = args[1]
    network_mode = int(network_mode)
except IndexError:
    network_mode = settings.NETWORK_MODE

#===============================================================================================
# Use Case 1
#===============================================================================================
# set floating IP as default route if available
# TODO: support more cloud providers
#===============================================================================================
if cloud_platform == 'DO' and network_mode == 0:
    # NOTE: we are using ipv4
    def hasFloatingIp():
        resp = requests.get(
            'http://169.254.169.254/metadata/v1/floating_ip/ipv4/active'
        ).text
        if resp == 'true':
            return True
        return False

    def getAnchorGateway():
        return requests.get(
            'http://169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/gateway'
        ).text

    def getAnchorIpAddr():
        return requests.get(
            'http://169.254.169.254/metadata/v1/interfaces/public/0/anchor_ipv4/address'
        ).text

    def ipAddrToIface(ip_addr):
        result = subprocess.run(
            ['ip', '-4', '-json', 'address', 'show'],
            capture_output=True,
            text=True
        )
        result_json = json.loads(result.stdout.strip())
        for iface_info in result_json:
            for addr_info in iface_info['addr_info']:
                if addr_info['local'] == ip_addr:
                    return iface_info['ifname']
        raise Exception(f'No matching Iface for IP {ip_addr}')

    def getDefRoutes():
        result = subprocess.run(
            ['ip', '-4', 'route', 'list', 'scope', 'global'],
            capture_output=True,
            text=True
        )
        routes = result.stdout.strip().split('\n')
        def_routes = []
        for route in routes:
            route_args = route.split(' ')
            if route_args[0] in ('default', '0.0.0.0/0'):
                def_routes.append(route_args)
        return def_routes

    def isIpDefRoute(check_ip):
        result = subprocess.run(
            ['ip', '-4', 'route', 'list', 'scope', 'global'],
            capture_output=True,
            text=True
        )
        route = result.stdout.strip().split('\n')[0]
        found = False
        for route_arg in route.split(' '):
            if found and route_arg == check_ip:
                return True
            if route_arg == 'via':
                found = True
        return False

    if hasFloatingIp():
        anchor_gw = getAnchorGateway()
        anchor_ip = getAnchorIpAddr()
        if not isIpDefRoute(anchor_gw):
            anchor_iface = ipAddrToIface(anchor_ip)
            def_routes = getDefRoutes()

            for route_args in def_routes:
                subprocess.run(
                    ['ip', 'route', 'delete', *route_args],
                    stdout=subprocess.DEVNULL
                )
            subprocess.run(
                ['ip', 'route', 'add', 'default', 'via', anchor_gw, 'dev', anchor_iface],
                stdout=subprocess.DEVNULL
            )

#===============================================================================================
# Default Case
#===============================================================================================
# do nothing
#===============================================================================================
exit(0)
