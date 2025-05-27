#!/bin/bash

# Flutter build komutunu çalıştırarak APK dosyasını oluştur
flutter build apk --release --split-per-abi  # APK'yı her ABI için ayrı olarak oluştur

# APK Dosyasının Yolu
APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"

# APK dosyasının varlığını kontrol et
if [ ! -f "$APK_PATH" ]; then
  echo "APK dosyası bulunamadı: $APK_PATH"
  exit 1
fi

# build.gradle dosyasının yolu
GRADLE_FILE="android/app/build.gradle"

# versionCode ve versionName değerlerini çek
VERSION_CODE=$(grep -m 1 "versionCode " $GRADLE_FILE | awk '{print $2}')
VERSION_NAME=$(grep -m 1 "versionName " $GRADLE_FILE | sed -E "s/.*versionName ['\"]([^'\"]+)['\"].*/\1/")

echo "versionCode: $VERSION_CODE"
echo "versionName: $VERSION_NAME"

# Uygulama adını 'AndroidManifest.xml' dosyasından al
APP_NAME=$(grep '<application' android/app/src/main/AndroidManifest.xml | sed -E 's/.*android:label="([^"]+)".*/\1/')

# Uygulama adını kontrol et
if [ -z "$APP_NAME" ]; then
  echo "Uygulama adı bulunamadı!"
  exit 1
fi

# Paket adını 'applicationId' kısmından al
PACKAGE_NAME=$(grep 'applicationId' "$GRADLE_FILE" | sed -E 's/.*applicationId[ ]*"?([^"]+)"?.*/\1/')

# Paket adını kontrol et
if [ -z "$PACKAGE_NAME" ]; then
  echo "Paket adı bulunamadı!"
  exit 1
fi

# Uygulama logosunu 'mipmap' dizininden al
LOGO_PATH="android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"  # mdpi logosu
if [ ! -f "$LOGO_PATH" ]; then
  echo "Uygulama logosu bulunamadı: $LOGO_PATH"
  exit 1
fi

echo "Uygulama Adı: $APP_NAME"
echo "Paket Adı: $PACKAGE_NAME"
echo "Version Name: $VERSION_NAME"
echo "Version Code: $VERSION_CODE"

# Dosya ve diğer bilgileri multipart/form-data ile API'ye gönder
curl -X POST http://213.142.148.177:13000/application/uploadApk \
  -H "Content-Type: multipart/form-data" \
  -F "file=@$APK_PATH" \
  -F "version_name=$VERSION_NAME" \
  -F "version_code=$VERSION_CODE" \
  -F "security_code=2580" \
  -F "app_name=$APP_NAME" \
  -F "package_name=$PACKAGE_NAME" \
  -F "logo=@$LOGO_PATH" \
  -v  # verbose output ile debug yaparak hata ayıklama
