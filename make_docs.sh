mkdir -p tmp
echo "- [Introduction](Intro.md)
- [Centralized Cluster Management](CM-intro.md)
    - [ACM Setup](ACM_Intro.md)
       - [Hub Cluster Installation](hub-cluster-readme.md)
        - [Machine Management In OCP](machine-intro.md)
        - [Machine Configuration](machineset-README.md)
        - [Spoke Cluster Deployment](spoke-cluster-readme.md)
    - [ACM Policies](acm-README.md)
- [Automation](Automation.md)
    - [ArgoCD](argo-README.md)
    - [ArgoCD - ApplicationSet](argo-appset-README.md)
- [Day 2 Components](Day2-intro.md)
    - [Cert Manager](cert-manager-README.md)
    - [External Secrets Manager](es-README.md)
    - [Trident Storage](trident-README.md)
    - [Velero Backup](velero-README.md)
    - [Customizing Routes](custom-route-README.md)
    - [MetalLB](metalLB-README.md)

" > tmp/summary.md


cd tmp
for file in 00-Intros/CM-intro.md 00-Intros/Intro.md 00-Intros/ACM_Intro.md  01-cluster-deploy/hub-cluster-readme.md  00-Intros/machine-intro.md  01-cluster-deploy/machineset-README.md  01-cluster-deploy/spoke-cluster-readme.md  03-acm-policy/acm-README.md  00-Intros/Automation.md  02-argo/argo-README.md  02-argo/argo-appset-README.md  00-Intros/Day2-intro.md  04-day2-configs/cert-manager-README.md  04-day2-configs/es-README.md  04-day2-configs/trident-README.md  04-day2-configs/velero-README.md  04-day2-configs/custom-route-README.md  04-day2-configs/metalLB-README.md; do
  ln -s ../src/"${file}"
done

cd ..

stitchmd -C tmp/ -o rendered/OCP_docs.md tmp/summary.md 

#rm -rf tmp
