# Enterprise Domain Lab: networking - virtualization - security


## Purpose

This lab simulates a medium-sized enterprise IT infrastructure using GNS3 and VMware.
It is designed to demonstrate and practice skills in:
- Virtualization
- Networking
- System administration
- Cybersecurity blue team and red team practices

The project is shared publicly as a showcase of my technical skills and as a resource for anyone who wants to experiment with enterprise networking and cybersecurity in their own lab.

---

## Devices

1.	1 WAN router – connected with my actual physical NIC
2.	1 distribution switch routing between the VLANS
3.	3 access switches managing the VLAN traffic
4.	Windows Server 2019 for main services like domain control, DNS, DHCP - TBA
5.	End-point machines; majority Windows 10 and some Linux distributions - TBA
6.	1 internal Kali attacker & 1 external Kali attacker – TBA
7.	Splunk, Snort, Pfsense as security tools – TBA

---

## Network design

1.	OSPF running between the WAN router and distro switch
2.	NAT setup between WAN router and external network
3.	VLANs & subnets:
	- VLAN10 Servers 10.10.10.0 /24
	- VLAN20 Operations 10.10.20.0 /24
	- VLAN30 Finance 10.10.30.0 /24
	- VLAN40 HR 10.10.40.0 /24
	- VLAN50 Infosec 10.10.50.0 /24
	- VLAN99 NetManagement 10.10.60.0 /24
	- VLAN100 Guest 10.10.70.0 /24
4.	LACP Etherchannels between distribution switch and access switches
5.	LLDP and CDP between all network devices *Sadly LLDP doesn't work on Cisco IOSvL2 switches
6.	STP; distro switch as root, portfast and bpduguard on downlinks to end-devices
7.	ACL to separate Guest network
8.	VTP transparent

**TBA:**

9.	DHCP
10.	DNS
11.	NTP
12.	LLDP agent on servers
13. ACLs to limit access between departments
14.	Port security, DHCP snooping, APR inspection
15.	SSH, FTP, TFTP connection to network devices
16. SNMP

---

## Host hardware

- SSD Lexar NM790 4TB M.2 2280 – I dedicated 3TB drive for the project, keeping my host OS on the same disk to ensure the best cooperation between the host OS and VMs
- AMD Ryzen 7 5800X 8-Core Processor, 3801 Mhz, 8 Cores, 16 Logical Processors
- 64 GB RAM Patriot Viper Steel, DDR4, 16x4 GB, 3200MHz, CL16

---

## Topology
![Topology](topology.jpg)

---

## Setup
The lab environment is built on my personal computer, running on my Win11 OS as the host OS.
After some considerations between GNS3 and Eve-Ng for network virtualization, the user interface and community support convinced me to GNS3. For now I just want to host the lab on my PC, no need to share the access to it. If I ever decide to rebuilt it on a separate server, I might migrate it to Even-Ng. 
For running the end-point VMs and GNS3 VM I use VMware Workstation. GNS3 VM runs all network devices + Windows Server.

I used Cisco Packet Tracer to create a testing environment.

---

## GNS3 + VMware configuration

Building up proper architecture of images of the network devices requires using GNS3 VM. That’s a purpose-built Linux VM that handles all these devices properly. Earlier I did some tests with Oracle Virtual Box, which couldn’t handle it. Key point here were:
- installing VMware Workstation
- installing VMware VIX
- downloading GNS3 VM from GNS3 website
- proper setup of GNS3; especially for server preferences and gns3 vm preferences to choose the same port that listens on GNS3 VM in VMware

<img src="readme_pictures/gns3_preferences.jpg" alt="Topology" width="75%">

---

## Dualboot

For my regular PC usage, I use WSL2. For this purpose I keep the Hyper-V enabled at Windows boot. This led to an issue. When Hyper-V is enabled, it locks the CPU’s virtualization engine, so other hypervisors like VMware can’t use it properly.
Turning it off would disable my WSL2. For this purpose I decided for a workaround – setting up a dualboot that allows:
- Default boot mode with Hyper-V enabled
- Secondary boot mode with Hyper-V disabled

Hyper-V can be checked in msinfo menu:
![msinfo Hyper-V](readme_pictures/msinfo_hyperv.jpg)

Useful commands here:
- `bcdedit /enum`
to see all the boot entries. By default there should be one
- `bcdedit /copy {default} /d "new-boot-entry-name"`
to copy the current boot entry
- `bcdedit /set {boot-entry-number} hypervisorlaunchtype off`
to turn off the hypervisor for the secondary boot entry

At this point I could restart PC to use the secondary boot (shift + restart button) but Hyper-V was remained enabled. Below two Windows features had to be enabled:

<img src="readme_pictures/windows_features.jpg" alt="Topology" width="45%">

Unchecking the features in GUI results in Hyper-V being disabled in both boot entries. I had to come up with some more handy solution so I prepared 2 scripts to toggle those 2 features and automatically reboot into the Advanced Startup Menu, so I can easily switch between my regular boot and boot for the lab purposes.

---

## Virtual Machines and allocated resources

- Cisco 8000V used as core router // 6144mb RAM and 2vCPU
- 1 x Cisco IOSvL2 used as distribution switch // 1024mb RAM and 1vCPU
- 3 x Cisco IOSvL2 used as access switches // 1024mb RAM and 1vCPU each

---

## VMware Workstation Player update to Pro

I needed to update the Workstation version to Pro in order to be able to map end-nodes into my network infrastructure. As of Nov 2024 Pro version is free and it offers this and few other useful features, such as cloning the VMs. The update had caused some troubles, though.

I had to completely remove VMware Workstation Player and remove Vmware VIX. Then download 17 Pro from Broadcom website (they took over Vmware). Then I started having issues with vmnetbridge.dll during installation. Seems that it's quite a common trouble, however fixing it took me a while. The library is needed as otherwise later the network adapter for GNS3 VM doesn't work so GNS3 cannot communicate with Vmware Workstation.

Solution: I removed the registries related to vmnetwork adapter, then then during the installation I pointed into the existing (new) folder of Vmware Workstation Pro (not the Player).

---

## Network adapters ##

3 different interface types had to be used here.

GNS3 VM is using the VMnet1 Host-only interface which is created by default in Virtual Network Editor via VMware Workstation. This way the management communication between my host PC and the GNS3 VM, hosting the network devices and servers, is separated from everything else.

Windows Server 2019 and 2016 are used within GNS3 VM, so no need for separate adapters.

WAN Router is connected to the cloud interface called, in my case, "ethernet". In practice it's my actual NIC interface in Bridge mode, so the lab router gets an IP directly from my home 
router.

End-nodes, like Win10/11 and Linux machines will use separate VMnet Host-only interfaces for each VLAN. There could be two solutions here. One to place a separate "end-devices" cloud on a single VMnet network adapter connected to a single access switch port in the lab. VMnet adapter works like an unmanaged switch, so the result would be having multiple mac addresses on a single access switch port in the lab. It's gonna work but will be less clear.
Since my lab is not that big and I prioritize to make it as realistic as possible I decided to go with the option for having 1 VMnet adapter per VM device.
That makes: 
1 VM (Windows/Linux/printer) == 1 VMnet adapter == 1 cloud device == 1 access switch port in the lab. In this case the VMnet adapter works more as an ethernet connection to a switch.

---

## Domain ##

I set up domain lab.local and Active Directory on Windows Server 2019. I created following OUs and users to populate the enterprise:
- NetManagement
- Operations
- HR
- Finance
- Infosec

DNS, DHCP and Windows Server 2016 as secondary DC TBA
Group Policies TBA

---

## End-devices & users ##

End user devices are set up in VMware, using VMnet adapters. All devices are added to the lab.local domain. All Windows 10 are linked clone copies of the Win10 in NetManagement VLAN making them lightweight but fine for the lab.

- Windows Server 2019 - as qemu device in GNS3 VM
- Windows Server 2016 - as qemu device in GNS3 VM - TBA
- Windows 10 in NetManagement VLAN; user adm.adrian; having access to RSAT and RDP for managing the Windows Server remotely
- Windows 10 in Operations VLAN; user ops.alex
- Windows 10 in Finance VLAN; user fin.john
- Windows 10 in HR VLAN; user hr.suzanne
- Windows 10 in Operations (separate); user ops.tom
- Linux in NetManagement VLAN for the administration of network infrastructure - TBA
- Kali Linux in Guest network TBA