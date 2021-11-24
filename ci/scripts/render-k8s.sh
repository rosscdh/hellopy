image_name=${1}
target_image=${2}
k8s_source_path=${3}
k8s_target_path=${4}
pushd ${k8s_source_path}
kustomize edit set image ${image_name}=${target_image}
kustomize build .> ${k8s_target_path} || exit 1
popd
