#!/usr/bin/env bash
#java 7 打出来的jar 才可以在在gradle tool3.0以下变成dex

cd `dirname $0`
echo `pwd`
ENGINE_SRC=`pwd`
ENGINE_OUT=${ENGINE_SRC}/out

FLUTTER_DIR=${1:-'~/Downloads/flutter'}  

FLUTTER_TARGET_CACHE=${FLUTTER_DIR}/bin/cache
ARTIFACTS_DIR=${FLUTTER_TARGET_CACHE}/artifacts
ENGINE_TARGET=${ARTIFACTS_DIR}/engine

REGENERATE=${2:-'true'}

cd $ENGINE_SRC

# cat $0
echo $ENGINE_TARGET
echo $ENGINE_OUT

# STEP1 generate engine artifacts
echo '=========STEP1========'

if [ $REGENERATE = 'true' ];then
    #【android-cpu默认就是arm，runtime-mode默认是debug】
    ./flutter/tools/gn --android --android-cpu=arm --runtime-mode=debug
    ./flutter/tools/gn --android --android-cpu=arm --runtime-mode=profile
    ./flutter/tools/gn --android --android-cpu=arm --runtime-mode=release
    ./flutter/tools/gn --android --android-cpu=arm --runtime-mode=profile --dynamic
    ./flutter/tools/gn --android --android-cpu=arm --runtime-mode=release --dynamic

    ./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=debug
    ./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=profile
    ./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=release
    ./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=profile --dynamic
    ./flutter/tools/gn --android --android-cpu=arm64 --runtime-mode=release --dynamic
    ./flutter/tools/gn --android --android-cpu=x86 
    ./flutter/tools/gn --android --android-cpu=x64
    #【—ios-cpu默认就是arm64,后面需要merge 所以先全打出来】
    ./flutter/tools/gn --ios --ios-cpu=arm --runtime-mode=release 
    ./flutter/tools/gn --ios --ios-cpu=arm --runtime-mode=profile
    ./flutter/tools/gn --ios --ios-cpu=arm --runtime-mode=debug --no-lto
    ./flutter/tools/gn --ios --simulator --runtime-mode=debug --no-lto
    ./flutter/tools/gn --ios --runtime-mode=debug --no-lto
    ./flutter/tools/gn --ios --runtime-mode=release 
    ./flutter/tools/gn --ios --runtime-mode=profile

    # host
    ./flutter/tools/gn  --runtime-mode=debug --no-lto
    ./flutter/tools/gn  --runtime-mode=release --dynamic
    ./flutter/tools/gn  --runtime-mode=debug --unoptimized --no-lto


    cd out
    for f in `ls | grep host`;do ninja -C $f;done
    for f in `ls | grep android`;do ninja -C $f flutter/lib/snapshot;done
    for f in `ls | grep ios`;do ninja -C $f;done
    

    # STEP3 Android armeabi支持
    echo '=========STEP3========'

    cd $ENGINE_OUT
    for f in `ls | grep android`;
        do 
        cd $f && pwd
        unzip -o flutter.jar lib/armeabi-v7a/libflutter.so
        mkdir lib/armeabi
        cp lib/armeabi-v7a/libflutter.so lib/armeabi/libflutter.so
        zip flutter.jar lib/armeabi-v7a/libflutter.so lib/armeabi/libflutter.so 
        pwd && cd .. && pwd ;
    done
fi

    # # STEP2 upload the engine dart part 2 MSS 
    # cd $ENGINE_OUT
    # zip -r host_debug/gen/dart-pkg.zip host_debug/gen/dart-pkg 
    # # todo upload 抽一下
    # #node /Users/liangting/AndroidStudioProjects/aimeituanmonitor/uploadMSS.js
    # SKY_ENGINE=""

# STEP4 modify original artifacts
echo '=========STEP4========'

# 替换engine中的文件Flutter.framework/flutter.jar(libflutter.so)/gen_snapshot 
cd $ENGINE_OUT

pwd
ARTIFACTS_FLUTTER_JAR=flutter.jar
ARTIFACTS_FLUTTER_FRAMEWORK=Flutter.framework
ARTIFACTS_FLUTTER_GEN_SNAPSHOT=gen_snapshot

# android-arm/flutter.jar
# android-arm-dynamic-profile/flutter.jar
# android-arm-dynamic-release/flutter.jar
# android-arm-profile/flutter.jar
# android-arm-release/flutter.jar
# android-arm64/flutter.jar
# android-arm64-dynamic-profile/flutter.jar
# android-arm64-dynamic-release/flutter.jar
# android-arm64-profile/flutter.jar
# android-arm64-release/flutter.jar
# android-x64/flutter.jar
# android-x86/flutter.jar

cp android_profile/${ARTIFACTS_FLUTTER_JAR}  ${ENGINE_TARGET}/android-arm-profile
cp android_debug/flutter.jar  ${ENGINE_TARGET}/android-arm
cp android_debug_arm64/flutter.jar  ${ENGINE_TARGET}/android-arm64
cp android_debug_x64/flutter.jar ${ENGINE_TARGET}/android-x64
cp android_debug_x86/flutter.jar ${ENGINE_TARGET}/android-x86
cp android_dynamic_profile/flutter.jar ${ENGINE_TARGET}/android-arm-dynamic-profile
cp android_dynamic_profile_arm64/flutter.jar ${ENGINE_TARGET}/android-arm64-dynamic-profile
cp android_dynamic_release/flutter.jar ${ENGINE_TARGET}/android-arm-dynamic-release
cp android_dynamic_release_arm64/flutter.jar ${ENGINE_TARGET}/android-arm64-dynamic-release
cp android_profile/flutter.jar  ${ENGINE_TARGET}/android-arm-profile
cp android_profile_arm64/flutter.jar ${ENGINE_TARGET}/android-arm64-profile
cp android_release/flutter.jar ${ENGINE_TARGET}/android-arm-release
cp android_release_arm64/flutter.jar ${ENGINE_TARGET}/android-arm64-release


# libflutter.so
# android-x64/libflutter.so
# android-x86/libflutter.so
cp android_debug_x64/libflutter.so ${ENGINE_TARGET}/android-x64
cp android_debug_x86/libflutter.so ${ENGINE_TARGET}/android-x86

# 这部分有gen_snapshot 
# android-arm-release/darwin-x64/gen_snapshot
# android-arm64-profile/darwin-x64/gen_snapshot
# android-arm64-release/darwin-x64/gen_snapshot
# ios/gen_snapshot
# ios-profile/gen_snapshot
# ios-release/gen_snapshot

cp android_release/clang_x86/gen_snapshot  ${ENGINE_TARGET}/android-arm-release/darwin-x64
cp android_profile_arm64/clang_x64/gen_snapshot ${ENGINE_TARGET}/android-arm64-profile/darwin-x64
cp android_release_arm64/clang_x64/gen_snapshot ${ENGINE_TARGET}/android-arm64-release/darwin-x64
cp ios_debug/clang_x64/gen_snapshot ${ENGINE_TARGET}/ios
cp ios_profile/clang_x64/gen_snapshot ${ENGINE_TARGET}/ios-profile
cp ios_release/clang_x64/gen_snapshot ${ENGINE_TARGET}/ios-release

# flutter_patched_sdk
# client side common flutter_patched_sdk
cp -r host_debug/flutter_patched_sdk/* ${ENGINE_TARGET}/common/flutter_patched_sdk

# darwin-x64 —— server side 
cp host_debug_unopt/flutter_tester ${ENGINE_TARGET}/darwin-x64
cp host_debug_unopt/gen/flutter/lib/snapshot/isolate_snapshot.bin ${ENGINE_TARGET}/darwin-x64
cp host_debug_unopt/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin  ${ENGINE_TARGET}/darwin-x64
cp host_debug_unopt/gen/frontend_server.dart.snapshot ${ENGINE_TARGET}/darwin-x64
cp host_dynamic_release/gen/flutter/lib/snapshot/isolate_snapshot.bin ${ENGINE_TARGET}/darwin-x64/product_isolate_snapshot.bin
cp host_dynamic_release/gen/flutter/lib/snapshot/vm_isolate_snapshot.bin ${ENGINE_TARGET}/darwin-x64/product_vm_isolate_snapshot.bin


# dart-sdk
cp -r host_debug/dart-sdk/* $FLUTTER_TARGET_CACHE/dart-sdk

#sky
cp -r host_debug/gen/dart-pkg/sky_engine/* $FLUTTER_TARGET_CACHE/pkg/sky_engine

# 这部分有Flutter.framework
# ios/Flutter.framework
# ios-profile/Flutter.framework
# ios-release/Flutter.framework
function PackageIOSVariant(){
  label=$1
  arm64_out=$2
  armv7_out=$3
  sim_out=$4
  target=$5
  checkout=$ENGINE_SRC
  out_dir=$ENGINE_OUT
  cd $ENGINE_SRC

  label_dir=$ENGINE_OUT/$label

  # Package the multi-arch framework for iOS.
  echo "PackageIOSVariant === "$label

  if [ $label = 'release' ];then 
    ./flutter/sky/tools/create_ios_framework.py --dst $label_dir --arm64-out-dir $out_dir/$arm64_out --armv7-out-dir $out_dir/$armv7_out --simulator-out-dir $out_dir/$sim_out --dsym --strip
  else
    ./flutter/sky/tools/create_ios_framework.py --dst $label_dir --arm64-out-dir $out_dir/$arm64_out --armv7-out-dir $out_dir/$armv7_out --simulator-out-dir $out_dir/$sim_out 
  fi

  # Zip Flutter.framework.
  echo "PackageIOSVariant === Archive Flutter.framework  "$label
  zip -r $label_dir/Flutter.framework.zip $label_dir/Flutter.framework

  # Package the multi-arch gen_snapshot for macOS.
  echo "PackageIOSVariant Create macOS "${label}" gen_snapshot"
  ./flutter/sky/tools/create_macos_gen_snapshot.py --dst $label_dir --arm64-out-dir $out_dir/$arm64_out --armv7-out-dir $out_dir/$armv7_out 

  cp -r $label_dir/* ${ENGINE_TARGET}/${target}

# ignore Flutter.podspec we did not change it
#   # Upload the artifacts to cloud storage.
#   artifacts = [
#     'flutter/shell/platform/darwin/ios/framework/Flutter.podspec',
#     'out/%s/gen_snapshot' % label,
#     'out/%s/Flutter.framework.zip' % label,
#   ]

}
PackageIOSVariant debug ios_debug ios_debug_arm ios_debug_sim ios
PackageIOSVariant profile ios_profile ios_profile_arm ios_debug_sim ios-profile
PackageIOSVariant release ios_release ios_release_arm ios_debug_sim ios-release

#STEP5 upload engine 
echo '=========STEP5========'

pushd ${ENGINE_SRC}/flutter
revision="$(git rev-parse HEAD)"
STAMP_PATH=${FLUTTER_DIR}/bin/cache/mtcache.stamp
echo "$revision" > "$STAMP_PATH"
popd

#full flutter
pushd ${FLUTTER_DIR}/..
zip -r flutter-MT.zip flutter
s3cmd put flutter-MT.zip s3://flutter/MTCustom/${revision}/flutter-MT.zip
#rm flutter-MT.zip
popd

#only cache
pushd ${FLUTTER_TARGET_CACHE}/..
zip -r flutter-MT-cache.zip cache
s3cmd put flutter-MT-cache.zip s3://flutter/MTCustom/${revision}/flutter-MT-cache.zip
rm flutter-MT-cache.zip
popd

echo "version flutter: "${revision}
echo "full flutter: "/flutter/MTCustom/${revision}/flutter-MT.zip
echo "flutter cache: "/flutter/MTCustom/${revision}/flutter-MT-cache.zip
