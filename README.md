japtr
=====
Jojess::Japtr
-------------
deb spider / apt repo builder

Setup
-----
* depends:
```

```

* update nginx conf host and certs
* stage nginx conf:
`sudo cp nginx* /etc/nginx/sites-enabled`

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
