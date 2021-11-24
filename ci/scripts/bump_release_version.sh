src_path=$1
pushd $src_path
semantic-release version
popd
