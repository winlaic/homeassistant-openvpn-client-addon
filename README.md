# OpenVPN Client Add-On for Home Assistant

This is a Add-On for [Home Assistant](https://www.home-assistant.io) which enables to tunnel the communication of your Home Assistant server with the world through a VPN connection.

## Change logs

The original repo could be found [here](https://github.com/Ailme/homeassistant-openvpn-client-addon), thanks to the author for his/her excellent work that helped me a lot.

The main contribution of this repo could be summarized as:

- I fixed the bug that the docker would shows "s6-overlay-suexec: fatal: can only run as pid 1" and fails to start.
- I added the option "interface" to config, to enable selection of the interface for the openvpn, in case that there are multiple available gateways.

## Installation

Move your client.ovpn file to hassio/share folder in your server.

Just navigate to the Hass.io panel in your Home Assistant frontend and add the OpenVPN Client add-on repository: https://github.com/winlaic/homeassistant-openvpn-client-addon

Then, scroll down and locate the OpenVPN Client Hass.io Add-Ons section. Click on OpenVPN Client, then INSTALL and Start.