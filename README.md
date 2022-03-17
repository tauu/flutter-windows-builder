# Windows image to build flutter desktop apps

These windows images are based upon ltsc2019 and have have all dependencies installed to build flutter desktop apps for windows.

## Create build using docker run

The images have an entrypoint script, which creates a release build of a flutter app mounted at `C:\src` within a container. After building the app the result is copied to `C:\src\build_container`.

### Example
Assuming the source of a flutter app is located at `C:\myapp` on your system, the following command will create a windows build of it and put the result into `C:\myapp\build_container`.
```sh
docker run --rm -v C:\myapp:C:\src tauu/flutter-windows-builder:latest
```

### Parameters
The following options can be specified as command line options to `docker run`.

   * `-example` Build the example app of a package mounted at `C:\src`.
   * `-msix` Create a msix package after building the app. This requires that the [msix package](https://pub.dev/packages/msix) has been added as a dev dependency to the app.

## CI/CD build

### Gitlab

The image can be used in a Gitlab CI job description to build a flutter app and provide the result build as an artifact. 

```yaml
build-windows:
  stage: build
  image:
    name: flutter-windows-builder:latest
    entrypoint: [""]
  script:
    - flutter clean
    - flutter build windows --release
  artifacts:
    paths:
      - build\windows\runner\Release\*
```
## Acknowledgements

The Dockerfile to create the image has been inspired by the [flutter-windows image](https://hub.docker.com/r/openpriv/flutter-desktop) created by [Open Privacy](https://git.openprivacy.ca/openprivacy/flutter-desktop).