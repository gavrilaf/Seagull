FROM swift:4

WORKDIR /build
COPY Sources ./Sources
COPY Tests ./Tests
COPY Package.swift .

RUN swift package resolve
RUN swift build

EXPOSE 8010

CMD ["/build/.build/x86_64-unknown-linux/debug/SgBaseRest"]