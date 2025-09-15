japtr
=====
Jojess::Japtr
-------------
deb spider / apt repo builder


<img width="772" height="649" alt="image" src="https://github.com/user-attachments/assets/2de2cec5-e440-4bfb-8297-55679de6b3a0" />
<img width="624" height="150" alt="image" src="https://github.com/user-attachments/assets/0bebbc9c-3a0d-40e7-9bc7-fa61a2b0174c" />


Setup
-----
* depends:
```
sudo apt install cpanm nginx nginx-extras fcgiwrap php8.2-fpm dpkg-dev gpg wget dpkg
sudo cpanm Getopt::Lazier
```

* update nginx conf host and certs
* stage nginx conf:
`sudo cp nginx/* /etc/nginx/sites-enabled/`

Using my repo, if u lazy:
-------------------------
* copy key
```
sudo cp jojess.pubkey /etc/apt/
```
* apt sources:
```
echo "deb [arch=amd64 signed-by=/etc/apt/jojess.pubkey ] https://deb.jojess.net stable main" | sudo tee /etc/apt/sources.list.d/deb.jojess.net.list
```
