FROM alpine:3.9 as builder

RUN apk update \
    && apk add alpine-sdk cmd:useradd cmd:usermod sudo xz \
    && useradd -m ffmpeg \
    && usermod -aG abuild ffmpeg \
    && echo 'ffmpeg ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

USER ffmpeg
WORKDIR /home/ffmpeg


RUN abuild-keygen -ain \
    && echo '/home/ffmpeg/packages/testing' | sudo tee -a /etc/apk/repositories \
    && wget 'https://git.alpinelinux.org/aports/snapshot/aports-3.9.2.tar.xz' \
    && tar xvpJf aports-3.9.2.tar.xz aports-3.9.2/community/ffmpeg aports-3.9.2/testing/fdk-aac
RUN (cd aports-3.9.2/testing/fdk-aac && abuild -r)
COPY APKBUILD.patch APKBUILD.patch
RUN ( \
        cd aports-3.9.2/community \
        && mv ffmpeg ffmpeg-libfdk \
        && cd ffmpeg-libfdk \
        && patch -i /home/ffmpeg/APKBUILD.patch APKBUILD \
        && abuild -r \
    )

FROM alpine:3.9

WORKDIR /root/
COPY --from=builder /home/ffmpeg/packages ./packages
COPY --from=builder /home/ffmpeg/.abuild/*.rsa.pub /etc/apk/keys/
RUN echo '/root/packages/community' >> /etc/apk/repositories \
    && echo '/root/packages/testing' >> /etc/apk/repositories \
    && apk add --no-cache ffmpeg-libfdk ffmpeg-libfdk-dev ffmpeg-libfdk-doc ffmpeg-libfdk-libs
CMD ["ffmpeg"]
