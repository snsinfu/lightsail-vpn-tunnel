[server]
tunnel public_address=${tunnel_public_address}

[server:vars]
ansible_host={{ public_address }}
