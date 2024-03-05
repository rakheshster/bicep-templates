Docker install instructions [here](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

We need to get that into `cloud-init`.

Thanks to [this](https://stackoverflow.com/questions/72620609/cloud-init-fetch-apt-key-from-remote-file-instead-of-from-a-key-server) post. 

```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  gpg --with-fingerprint --with-colons | awk -F: '/^fpr/ { print $10 }'

gpg: WARNING: no command supplied.  Trying to guess what you mean ...
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   4  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 4u
gpg: next trustdb check due at 2024-12-11
9DC858229FC7DD38854AE2D88D81803C0EBFCD88

$ gpg --keyserver=keyserver.ubuntu.com --recv-keys 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
gpg: key 8D81803C0EBFCD88: 1 duplicate signature removed
gpg: key 8D81803C0EBFCD88: public key "Docker Release (CE deb) <docker@docker.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

---

Also thanks to [this](https://www.jeroentrimbach.com/2023/02/cloud-init-ado/) blog post.
And [Microsoft](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-automate-vm-deployment)