# dmeupdate.rb

A [dynamic DNS][2] update script for [DNS Made Easy][1].

[1]: http://www.dnsmadeeasy.com
[2]: http://www.dnsmadeeasy.com/services/dynamic-dns

## Usage

Update dmeupdate.yaml with your DNS Made Easy settings. Run the script:

```
ruby dmeupdate.rb
```
The script will discover your externally visible IP Address and update the
service appropriately.


If Ruby gives trouble about `certificate verify failed (OpenSSL::SSL::SSLError)`
you can try something like this:

```
ruby -ropenssl -e "p OpenSSL::X509::DEFAULT_CERT_FILE"
wget -O /etc/ssl/cert.pem http://curl.haxx.se/ca/cacert.pem
```
Google for details or alternate solutions if you run into trouble.
