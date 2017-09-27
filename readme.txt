The following are the prerequisites for the masterdeploy.sh

1. Bars, mq scripts, sql scripts and bo are placed under /staging/i2mpTicketDeployments/<i2mpticket>/ in respective folders - bars, mq, sql, bo.
2. User passes the i2mp ticket number (folder name in the above) as a parameter to the script
3. The files eglist.cfg, override.properties are present in /staging/i2mpTicketDeployments

About eglist.cfg:

It has 3 sections
1. It has interface ids listed against execution groups i.e, in each line first column is execution group and rest of the columns are interface ids.
2. Environment specific values required by the mqsideploy command - ip address, config queue manager, config queue manager port, broker. The intention of having the values in eglist.cfg is to make the script generic and independent of environment specific values.
3. Connector server ips for BO deployment.

About override.properties:

It has value pairs to be overriden.

For BO deployment, remote login from broker server to adapters server using ssh is required in the script. To avoid prompting for password the following is to be done.

mqsi@eu1pmwu012: /home/mqsi  > ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/mqsi/.ssh/id_rsa): 
Created directory '/home/mqsi/.ssh'.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/mqsi/.ssh/id_rsa.
Your public key has been saved in /home/mqsi/.ssh/id_rsa.pub.
The key fingerprint is:
3e:4f:05:79:3a:9f:96:7c:3b:ad:e9:58:37:bc:37:e4 mqsi@eu1pmwu012

Now use ssh to create a directory ~/.ssh as user mqsi on eu1pmwu011. (The directory may already exist, which is fine):
mqsi@eu1pmwu012: /home/mqsi  > ssh mqsi@eu1pmwu011 mkdir -p .ssh
b@B's password: 

Finally append a's new public key to mqsi@eu1pmwu011:.ssh/authorized_keys and enter mqsi's password one last time:
mqsi@eu1pmwu012: /home/mqsi  > cat .ssh/id_rsa.pub | ssh mqsi@eu1pmwu011 'cat >> .ssh/authorized_keys'
mqsi@eu1pmwu011's password: 

From now on you can log into eu1pmwu011 as mqsi from eu1pmwu012 as mqsi without password:
mqsi@eu1pmwu012: /home/mqsi  > ssh mqsi@eu1pmwu011

