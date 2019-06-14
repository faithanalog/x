# Artemis' Upload Server

Alright this is just a simple upload server for us to use internally, email us
or something if you want to know how to use it.

The gist though is like:

```
bundle install
HOST=127.0.0.1 PORT=9009 UPLOAD_PATH=./files AUTH_TOKEN=aaaabbbbccccdddd HOST_PREFIX='http://127.0.0.1:9009' ruby artemis-upload-service.rb
```

Or use `./install.sh` to install it as a service, and edit
`/etc/artemis-upload-service.conf`
