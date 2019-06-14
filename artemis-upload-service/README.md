# Artemis' Upload Server

Alright this is just a simple upload server for us to use internally, email us
or something if you want to know how to use it.

The gist though is like:

```
bundle install
HOST=0.0.0.0 PORT=4567 UPLOAD_PATH=public/files AUTH_TOKEN=<random> HOST_PREFIX='http://127.0.0.1:4567/files' ruby artemis-upload-service.rb
```

Or use `artemis-upload-service.service` and put `artemis-upload-service.conf`
in `/etc`
