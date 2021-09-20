provider "azurerm" {
  features {}
}

resource azurerm_resource_group "reg1"{
	
	name = "mmps-reg"
	location = "westus2"
}




resource "azurerm_kubernetes_cluster" "cluster1"{
	name = "prasad-cluster"
	location = azurerm_resource_group.reg1.location
	resource_group_name = azurerm_resource_group.reg1.name
  dns_prefix = "mmpsprivate888"

  identity {
    type = "SystemAssigned"
  }



	default_node_pool{
		name = "manupool"
		node_count = 2
		vm_size = "Standard_D2_V2"
	}

	linux_profile {
		admin_username = "ubuntu"
	

	ssh_key{

      key_data = "${file("/home/manuprasad/.ssh/id_rsa.pub")}"
   }
}
}


resource "local_file" "kube_config" {
  content    = azurerm_kubernetes_cluster.cluster1.kube_admin_config_raw
  filename   = ".kube/config"   
}


resource "null_resource" "set-kube-config" {
  triggers = {
    always_run = "${timestamp()}"
 }


  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.cluster1.name} -g ${azurerm_resource_group.reg1.name} --file \"/home/manuprasad/.kube/config\" --admin --overwrite-existing"
  }
  depends_on = [local_file.kube_config]
}


provider "kubernetes" {
  config_path    = "/home/manuprasad/.kube/config"
  config_context = "prasad-cluster-admin"
}

provider "helm" {
  kubernetes {
    config_path = "/home/manuprasad/.kube/config"
  }
}


#adding the resources to the kubernetes landscape



resource "kubernetes_namespace" "istio_system" {

  
  metadata {
    name = "istio-system"
  }
}


resource "helm_release" "istio-base" {
  name       = "istio-chart1"
  chart      = "/home/manuprasad/istio-1.11.2/manifests/charts/base/"
  namespace =  "istio-system"
}

resource "helm_release" "istio-discovery" {
  name       = "istio-chart2"
  chart      = "/home/manuprasad/istio-1.11.2/manifests/charts/istio-control/istio-discovery"
  namespace =  "istio-system"
}


resource "helm_release" "istio-ingress" {
  name       = "istio-chart3"
  chart      = "/home/manuprasad/istio-1.11.2/manifests/charts/gateways/istio-ingress"
  namespace =  "istio-system"
}

resource "helm_release" "istio-egress" {
  name       = "istio-chart4"
  chart      = "/home/manuprasad/istio-1.11.2/manifests/charts/gateways/istio-egress"
  namespace =  "istio-system"
}

resource "null_resource" "installing-istio" {
  triggers = {
    always_run = "${timestamp()}"
 }



  provisioner "local-exec" {
    command = <<EOT
    kubectl apply -f /home/manuprasad/istio-1.11.2/samples/addons/prometheus.yaml
    kubectl apply -f /home/manuprasad/istio-1.11.2/samples/addons/grafana.yaml
    kubectl apply -f /home/manuprasad/istio-1.11.2/samples/addons/kiali.yaml
     EOT
  }
  depends_on = [helm_release.istio-egress,helm_release.istio-ingress,helm_release.istio-discovery,helm_release.istio-base]
}







